use crate::module::{as_module_map, Module, ModuleMap};
use futures_core::{ready, task::Context};
use std::{cell::RefCell, fmt::Debug, future::Future, io, sync::Arc};
use tokio::{
    macros::support::{Pin, Poll},
    sync::{
        mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender},
        oneshot,
    },
};

thread_local!(
    static CURRENT: RefCell<Option<Arc<FlowySystem>>> = RefCell::new(None);
);

#[derive(Debug)]
#[allow(dead_code)]
pub enum SystemCommand {
    Exit(i8),
}

pub struct FlowySystem {
    sys_cmd_tx: UnboundedSender<SystemCommand>,
}

impl FlowySystem {
    #[allow(dead_code)]
    pub fn construct<F, S>(module_factory: F, sender_factory: S) -> SystemRunner
    where
        F: FnOnce() -> Vec<Module>,
        S: FnOnce(ModuleMap, &Runtime),
    {
        let runtime = Arc::new(Runtime::new().unwrap());
        let (sys_cmd_tx, sys_cmd_rx) = unbounded_channel::<SystemCommand>();
        let (stop_tx, stop_rx) = oneshot::channel();

        runtime.spawn(SystemController {
            stop_tx: Some(stop_tx),
            sys_cmd_rx,
        });

        let module_map = as_module_map(module_factory());
        sender_factory(module_map, &runtime);

        let system = Self { sys_cmd_tx };
        FlowySystem::set_current(system);
        SystemRunner { rt: runtime, stop_rx }
    }

    #[allow(dead_code)]
    pub fn stop(&self) {
        match self.sys_cmd_tx.send(SystemCommand::Exit(0)) {
            Ok(_) => {},
            Err(e) => {
                log::error!("Stop system error: {}", e);
            },
        }
    }

    #[allow(dead_code)]
    pub fn set_current(sys: FlowySystem) {
        CURRENT.with(|cell| {
            *cell.borrow_mut() = Some(Arc::new(sys));
        })
    }

    #[allow(dead_code)]
    pub fn current() -> Arc<FlowySystem> {
        CURRENT.with(|cell| match *cell.borrow() {
            Some(ref sys) => sys.clone(),
            None => panic!("System is not running"),
        })
    }
}

struct SystemController {
    stop_tx: Option<oneshot::Sender<i8>>,
    sys_cmd_rx: UnboundedReceiver<SystemCommand>,
}

impl Future for SystemController {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.sys_cmd_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(cmd) => match cmd {
                    SystemCommand::Exit(code) => {
                        if let Some(tx) = self.stop_tx.take() {
                            let _ = tx.send(code);
                        }
                    },
                },
            }
        }
    }
}

pub struct SystemRunner {
    rt: Arc<Runtime>,
    stop_rx: oneshot::Receiver<i8>,
}

impl SystemRunner {
    #[allow(dead_code)]
    pub fn run(self) -> io::Result<()> {
        let SystemRunner { rt, stop_rx } = self;
        match rt.block_on(stop_rx) {
            Ok(code) => {
                if code != 0 {
                    Err(io::Error::new(
                        io::ErrorKind::Other,
                        format!("Non-zero exit code: {}", code),
                    ))
                } else {
                    Ok(())
                }
            },
            Err(e) => Err(io::Error::new(io::ErrorKind::Other, e)),
        }
    }

    #[allow(dead_code)]
    pub fn spawn<F: Future<Output = ()> + 'static>(self, future: F) -> Self {
        self.rt.spawn(future);
        self
    }
}

use crate::util::tokio_default_runtime;
use tokio::{runtime, task::LocalSet};

#[derive(Debug)]
pub struct Runtime {
    local: LocalSet,
    rt: runtime::Runtime,
}

impl Runtime {
    #[allow(dead_code)]
    pub fn new() -> io::Result<Runtime> {
        let rt = tokio_default_runtime()?;
        Ok(Runtime {
            rt,
            local: LocalSet::new(),
        })
    }

    #[allow(dead_code)]
    pub fn spawn<F>(&self, future: F) -> &Self
    where
        F: Future<Output = ()> + 'static,
    {
        self.local.spawn_local(future);
        self
    }

    #[allow(dead_code)]
    pub fn block_on<F>(&self, f: F) -> F::Output
    where
        F: Future + 'static,
    {
        self.local.block_on(&self.rt, f)
    }
}
