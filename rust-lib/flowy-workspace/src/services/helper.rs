pub fn spawn<F>(f: F)
where
    F: std::future::Future + Send + 'static,
    F::Output: Send + 'static,
{
    let _ = tokio::spawn(f);
}
