#[macro_export]
macro_rules! dispatch_future {
  ($fut:expr) => {
    DispatchFuture {
      fut: Box::pin(async move { $fut.await }),
    }
  };
}
