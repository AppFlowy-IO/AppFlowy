use std::future::Future;
use std::io;

use tokio::runtime;
use tokio::runtime::Runtime;
use tokio::task::JoinHandle;

pub struct AFPluginRuntime {
  inner: Runtime,
  #[cfg(feature = "single_thread")]
  local: tokio::task::LocalSet,
}
impl AFPluginRuntime {
  pub fn new() -> io::Result<Self> {
    let inner = default_tokio_runtime()?;
    Ok(Self {
      inner,
      #[cfg(feature = "single_thread")]
      local: tokio::task::LocalSet::new(),
    })
  }

  #[cfg(feature = "single_thread")]
  #[track_caller]
  pub fn spawn<F>(&self, future: F) -> JoinHandle<F::Output>
  where
    F: Future + 'static,
  {
    self.local.spawn_local(future)
  }

  #[cfg(not(feature = "single_thread"))]
  #[track_caller]
  pub fn spawn<F>(&self, future: F) -> JoinHandle<F::Output>
  where
    F: Future + Send + 'static,
    <F as Future>::Output: Send + 'static,
  {
    self.inner.spawn(future)
  }

  #[cfg(feature = "single_thread")]
  #[track_caller]
  pub fn block_on<F>(&self, f: F) -> F::Output
  where
    F: Future,
  {
    self.local.block_on(&self.inner, f)
  }

  #[cfg(not(feature = "single_thread"))]
  #[track_caller]
  pub fn block_on<F>(&self, f: F) -> F::Output
  where
    F: Future,
  {
    self.inner.block_on(f)
  }
}

#[cfg(feature = "single_thread")]
pub fn default_tokio_runtime() -> io::Result<Runtime> {
  runtime::Builder::new_current_thread()
    .thread_name("dispatch-rt-st")
    .enable_io()
    .enable_time()
    .build()
}

#[cfg(not(feature = "single_thread"))]
pub fn default_tokio_runtime() -> io::Result<Runtime> {
  runtime::Builder::new_multi_thread()
    .thread_name("dispatch-rt-mt")
    .enable_io()
    .enable_time()
    .on_thread_start(move || {
      tracing::trace!(
        "{:?} thread started: thread_id= {}",
        thread::current(),
        thread_id::get()
      );
    })
    .on_thread_stop(move || {
      tracing::trace!(
        "{:?} thread stopping: thread_id= {}",
        thread::current(),
        thread_id::get(),
      );
    })
    .build()
}
