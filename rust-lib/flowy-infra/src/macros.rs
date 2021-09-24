#[macro_export]
macro_rules! wrap_future_fn {
    ($fut:expr) => {
        ClosureFuture {
            fut: Box::pin(async move { $fut.await }),
        }
    };
}
