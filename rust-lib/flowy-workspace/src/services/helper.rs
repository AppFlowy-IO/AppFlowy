pub async fn spawn<F>(f: F)
where
    F: std::future::Future + Send + 'static,
    F::Output: Send + 'static,
{
    match tokio::spawn(f).await {
        Ok(_) => {},
        Err(e) => log::error!("{:?}", e),
    }
}
