use std::{
  collections::HashMap,
  io::{BufReader, Write},
  path::PathBuf,
  process::{Command as StdCommand, Stdio},
  sync::{Arc, Mutex, RwLock},
};

#[cfg(unix)]
use std::os::unix::process::ExitStatusExt;
#[cfg(windows)]
use std::os::windows::process::CommandExt;

#[cfg(windows)]
const CREATE_NO_WINDOW: u32 = 0x0800_0000;

use crate::process::runtime::block_on;
use crate::utils;
use crate::utils::platform;
use anyhow::{anyhow, Result};
pub use encoding_rs::Encoding;
use os_pipe::{pipe, PipeReader, PipeWriter};
use serde::Serialize;
use shared_child::SharedChild;
use tokio::sync::mpsc::{channel, Receiver, Sender};
use tracing::{error, trace};

type ChildStore = Arc<Mutex<HashMap<u32, Arc<SharedChild>>>>;

fn commands() -> &'static ChildStore {
  use once_cell::sync::Lazy;
  static STORE: Lazy<ChildStore> = Lazy::new(Default::default);
  &STORE
}

/// Kills all child processes created with [`SidecarCommand`].
pub fn kill_children() {
  let commands = commands().lock().unwrap();
  let children = commands.values();
  for child in children {
    let _ = child.kill();
  }
}

/// Payload for the [`CommandEvent::Terminated`] command event.
#[derive(Debug, Clone, Serialize)]
pub struct TerminatedPayload {
  /// Exit code of the process.
  pub code: Option<i32>,
  /// If the process was terminated by a signal, represents that signal.
  pub signal: Option<i32>,
}

/// A event sent to the command callback.
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "event", content = "payload")]
#[non_exhaustive]
pub enum CommandEvent {
  /// Stderr bytes until a newline (\n) or carriage return (\r) is found.
  Stderr(String),
  /// Stdout bytes until a newline (\n) or carriage return (\r) is found.
  Stdout(String),
  /// An error happened waiting for the command to finish or converting the stdout/stderr bytes to an UTF-8 string.
  Error(String),
  /// Command process terminated.
  Terminated(TerminatedPayload),
}

/// The type to spawn commands.
#[derive(Debug)]
pub struct SidecarCommand {
  program: String,
  args: Vec<String>,
  env_clear: bool,
  env: HashMap<String, String>,
  current_dir: Option<PathBuf>,
  encoding: Option<&'static Encoding>,
}

/// Spawned child process.
#[derive(Debug)]
pub struct CommandChild {
  inner: Arc<SharedChild>,
  stdin_writer: PipeWriter,
}

impl CommandChild {
  /// Writes to process stdin.
  pub fn write(&mut self, buf: &[u8]) -> Result<()> {
    self.stdin_writer.write_all(buf)?;
    Ok(())
  }

  pub fn write_json(&mut self, value: serde_json::Value) -> Result<()> {
    let s = value.to_string();
    self.write(s.as_bytes())?;
    Ok(())
  }

  /// Sends a kill signal to the child.
  pub fn kill(self) -> Result<()> {
    self.inner.kill()?;
    Ok(())
  }

  /// Returns the process pid.
  pub fn pid(&self) -> u32 {
    self.inner.id()
  }
}

/// Describes the result of a process after it has terminated.
#[derive(Debug)]
pub struct ExitStatus {
  code: Option<i32>,
}

impl ExitStatus {
  /// Returns the exit code of the process, if any.
  pub fn code(&self) -> Option<i32> {
    self.code
  }

  /// Returns true if exit status is zero. Signal termination is not considered a success, and success is defined as a zero exit status.
  pub fn success(&self) -> bool {
    self.code == Some(0)
  }
}

/// The output of a finished process.
#[derive(Debug)]
pub struct Output {
  /// The status (exit code) of the process.
  pub status: ExitStatus,
  /// The data that the process wrote to stdout.
  pub stdout: String,
  /// The data that the process wrote to stderr.
  pub stderr: String,
}

#[allow(dead_code)]
fn relative_command_path(command: String) -> Result<String> {
  match platform::current_exe()?.parent() {
    #[cfg(windows)]
    Some(exe_dir) => Ok(format!("{}\\{command}.exe", exe_dir.display())),
    #[cfg(not(windows))]
    Some(exe_dir) => Ok(format!("{}/{command}", exe_dir.display())),
    None => Err(anyhow!("Could not evaluate executable dir".to_string())),
  }
}

impl From<SidecarCommand> for StdCommand {
  fn from(cmd: SidecarCommand) -> StdCommand {
    let mut command = StdCommand::new(cmd.program);
    command.args(cmd.args);
    command.stdout(Stdio::piped());
    command.stdin(Stdio::piped());
    command.stderr(Stdio::piped());
    if cmd.env_clear {
      command.env_clear();
    }
    command.envs(cmd.env);
    if let Some(current_dir) = cmd.current_dir {
      command.current_dir(current_dir);
    }
    #[cfg(windows)]
    command.creation_flags(CREATE_NO_WINDOW);
    command
  }
}

impl SidecarCommand {
  /// Creates a new Command for launching the given program.
  pub fn new<S: Into<String>>(program: S) -> Self {
    let program = program.into();
    Self {
      program,
      args: Default::default(),
      env_clear: false,
      env: Default::default(),
      current_dir: None,
      encoding: None,
    }
  }

  /// Creates a new Command for launching the given sidecar program.
  ///
  /// A sidecar program is a embedded external binary in order to make your application work
  /// or to prevent users having to install additional dependencies (e.g. Node.js, Python, etc).
  pub fn new_sidecar<S: Into<String>>(program: S) -> Result<Self> {
    let program = program.into();
    Ok(Self::new(program))
  }

  /// Appends arguments to the command.
  #[must_use]
  pub fn args<I, S>(mut self, args: I) -> Self
  where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
  {
    for arg in args {
      self.args.push(arg.as_ref().to_string());
    }
    self
  }

  /// Clears the entire environment map for the child process.
  #[must_use]
  pub fn env_clear(mut self) -> Self {
    self.env_clear = true;
    self
  }

  /// Adds or updates multiple environment variable mappings.
  #[must_use]
  pub fn envs(mut self, env: HashMap<String, String>) -> Self {
    self.env = env;
    self
  }

  /// Sets the working directory for the child process.
  #[must_use]
  pub fn current_dir(mut self, current_dir: PathBuf) -> Self {
    self.current_dir.replace(current_dir);
    self
  }

  /// Sets the character encoding for stdout/stderr.
  #[must_use]
  pub fn encoding(mut self, encoding: &'static Encoding) -> Self {
    self.encoding.replace(encoding);
    self
  }
  pub fn spawn(self) -> Result<(Receiver<CommandEvent>, CommandChild)> {
    let encoding = self.encoding;
    let mut command: StdCommand = self.into();
    let (stdout_reader, stdout_writer) = pipe()?;
    let (stderr_reader, stderr_writer) = pipe()?;
    let (stdin_reader, stdin_writer) = pipe()?;
    command.stdout(stdout_writer);
    command.stderr(stderr_writer);
    command.stdin(stdin_reader);

    let shared_child = SharedChild::spawn(&mut command)?;
    let child = Arc::new(shared_child);
    let child_ = child.clone();
    let guard = Arc::new(RwLock::new(()));

    commands().lock().unwrap().insert(child.id(), child.clone());

    let (tx, rx) = channel(1);

    spawn_pipe_reader(
      tx.clone(),
      guard.clone(),
      stdout_reader,
      CommandEvent::Stdout,
      encoding,
    );
    spawn_pipe_reader(
      tx.clone(),
      guard.clone(),
      stderr_reader,
      CommandEvent::Stderr,
      encoding,
    );

    std::thread::spawn(move || {
      let _ = match child_.wait() {
        Ok(status) => {
          let _l = guard.write().unwrap();
          commands().lock().unwrap().remove(&child_.id());
          block_on(async move {
            tx.send(CommandEvent::Terminated(TerminatedPayload {
              code: status.code(),
              #[cfg(windows)]
              signal: None,
              #[cfg(unix)]
              signal: status.signal(),
            }))
            .await
          })
        },
        Err(e) => {
          let _l = guard.write().unwrap();
          block_on(async move { tx.send(CommandEvent::Error(e.to_string())).await })
        },
      };
    });

    Ok((
      rx,
      CommandChild {
        inner: child,
        stdin_writer,
      },
    ))
  }

  pub async fn status(self) -> Result<ExitStatus> {
    let (mut rx, _child) = self.spawn()?;
    let mut code = None;
    #[allow(clippy::collapsible_match)]
    while let Some(event) = rx.recv().await {
      if let CommandEvent::Terminated(payload) = event {
        code = payload.code;
      }
    }
    Ok(ExitStatus { code })
  }

  pub async fn output(self) -> Result<Output> {
    let (mut rx, _child) = self.spawn()?;
    let mut code = None;
    let mut stdout = String::new();
    let mut stderr = String::new();
    while let Some(event) = rx.recv().await {
      match event {
        CommandEvent::Terminated(payload) => {
          code = payload.code;
        },
        CommandEvent::Stdout(line) => {
          stdout.push_str(line.as_str());
          stdout.push('\n');
        },
        CommandEvent::Stderr(line) => {
          stderr.push_str(line.as_str());
          stderr.push('\n');
        },
        CommandEvent::Error(_) => {},
      }
    }
    Ok(Output {
      status: ExitStatus { code },
      stdout,
      stderr,
    })
  }
}

fn spawn_pipe_reader<F: Fn(String) -> CommandEvent + Send + Copy + 'static>(
  tx: Sender<CommandEvent>,
  guard: Arc<RwLock<()>>,
  pipe_reader: PipeReader,
  wrapper: F,
  character_encoding: Option<&'static Encoding>,
) {
  std::thread::spawn(move || {
    let _lock = guard.read().unwrap();
    let mut reader = BufReader::new(pipe_reader);

    let mut buf = Vec::new();
    loop {
      buf.clear();
      match utils::io::read_line(&mut reader, &mut buf) {
        Ok(n) => {
          if n == 0 {
            break;
          }
          let tx_ = tx.clone();
          let line = match character_encoding {
            Some(encoding) => Ok(encoding.decode_with_bom_removal(&buf).0.into()),
            None => String::from_utf8(buf.clone()),
          };
          block_on(async move {
            let _ = match line {
              Ok(line) => {
                trace!("{}", line);
                tx_.send(wrapper(line)).await
              },
              Err(e) => tx_.send(CommandEvent::Error(e.to_string())).await,
            };
          });
        },
        Err(e) => {
          let tx_ = tx.clone();
          let _ = block_on(async move { tx_.send(CommandEvent::Error(e.to_string())).await });
        },
      }
    }
  });
}
