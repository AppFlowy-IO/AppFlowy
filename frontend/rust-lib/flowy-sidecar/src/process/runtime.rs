use once_cell::sync::OnceCell;

use std::future::Future;
use tokio::runtime::{Handle, Runtime};
use tokio::task::JoinHandle;

static RUNTIME: OnceCell<GlobalRuntime> = OnceCell::new();

struct GlobalRuntime {
  runtime: Option<Runtime>,
  handle: Handle,
}

impl GlobalRuntime {
  fn handle(&self) -> &Handle {
    if let Some(r) = &self.runtime {
      r.handle()
    } else {
      &self.handle
    }
  }

  fn spawn<F: Future>(&self, task: F) -> JoinHandle<F::Output>
  where
    F: Future + Send + 'static,
    F::Output: Send + 'static,
  {
    if let Some(r) = &self.runtime {
      r.spawn(task)
    } else {
      self.handle.spawn(task)
    }
  }

  pub fn spawn_blocking<F, R>(&self, func: F) -> JoinHandle<R>
  where
    F: FnOnce() -> R + Send + 'static,
    R: Send + 'static,
  {
    if let Some(r) = &self.runtime {
      r.spawn_blocking(func)
    } else {
      self.handle.spawn_blocking(func)
    }
  }

  fn block_on<F: Future>(&self, task: F) -> F::Output {
    if let Some(r) = &self.runtime {
      r.block_on(task)
    } else {
      self.handle.block_on(task)
    }
  }
}

pub fn block_on<F: Future>(task: F) -> F::Output {
  let runtime = RUNTIME.get_or_init(default_runtime);
  runtime.block_on(task)
}

pub fn spawn<F>(task: F) -> JoinHandle<F::Output>
where
  F: Future + Send + 'static,
  F::Output: Send + 'static,
{
  let runtime = RUNTIME.get_or_init(default_runtime);
  runtime.spawn(task)
}

pub fn spawn_blocking<F, R>(func: F) -> JoinHandle<R>
where
  F: FnOnce() -> R + Send + 'static,
  R: Send + 'static,
{
  let runtime = RUNTIME.get_or_init(default_runtime);
  runtime.spawn_blocking(func)
}

fn default_runtime() -> GlobalRuntime {
  let runtime = Runtime::new().unwrap();
  let handle = runtime.handle().clone();
  GlobalRuntime {
    runtime: Some(runtime),
    handle,
  }
}
