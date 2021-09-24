#[macro_export]
macro_rules! dispatch_future {
    ($fut:expr) => {
        ClosureFuture {
            fut: Box::pin(async move { $fut.await }),
        }
    };
}
