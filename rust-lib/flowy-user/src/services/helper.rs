use std::future::Future;

pub fn spawn<F>(f: F)
where
    F: Future + Send + 'static,
    F::Output: Send + 'static,
{
    tokio::spawn(f);
}
