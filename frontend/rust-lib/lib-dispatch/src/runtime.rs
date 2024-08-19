use std::fmt::{Display, Formatter};
use std::future::Future;
use std::io;

use tokio::runtime;
use tokio::runtime::Runtime;
use tokio::task::JoinHandle;

pub struct AFPluginRuntime {
  pub(crate) inner: Runtime,
}

impl Display for AFPluginRuntime {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    if cfg!(any(target_arch = "wasm32", feature = "local_set")) {
      write!(f, "Runtime(local_set)")
    } else {
      write!(f, "Runtime")
    }
  }
}

impl AFPluginRuntime {
  pub fn new() -> io::Result<Self> {
    let inner = default_tokio_runtime()?;
    Ok(Self { inner })
  }

  #[track_caller]
  pub fn spawn<F>(&self, future: F) -> JoinHandle<F::Output>
  where
    F: Future + Send + 'static,
    <F as Future>::Output: Send + 'static,
  {
    self.inner.spawn(future)
  }

  #[track_caller]
  pub fn block_on<F>(&self, f: F) -> F::Output
  where
    F: Future,
  {
    self.inner.block_on(f)
  }
}

#[cfg(feature = "local_set")]
pub fn default_tokio_runtime() -> io::Result<Runtime> {
  runtime::Builder::new_multi_thread()
    .enable_io()
    .enable_time()
    .thread_name("dispatch-rt-st")
    .build()
}

#[cfg(not(feature = "local_set"))]
pub fn default_tokio_runtime() -> io::Result<Runtime> {
  runtime::Builder::new_multi_thread()
    .thread_name("dispatch-rt-mt")
    .enable_io()
    .enable_time()
    .on_thread_start(move || {
      tracing::trace!(
        "{:?} thread started: thread_id= {}",
        std::thread::current(),
        thread_id::get()
      );
    })
    .on_thread_stop(move || {
      tracing::trace!(
        "{:?} thread stopping: thread_id= {}",
        std::thread::current(),
        thread_id::get(),
      );
    })
    .build()
}
