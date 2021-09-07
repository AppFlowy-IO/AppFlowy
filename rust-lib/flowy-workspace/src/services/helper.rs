use tokio::task::JoinHandle;

pub fn spawn<F>(f: F) -> JoinHandle<F::Output>
where
    F: std::future::Future + Send + 'static,
    F::Output: Send + 'static,
{
    tokio::spawn(f)
}
