use crate::{module::WorkspaceUser, services::server::Server};
use flowy_infra::retry::Action;
use pin_project::pin_project;
use std::{
    future::Future,
    marker::PhantomData,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};

pub(crate) type Builder<Fut> = Box<dyn Fn(String, Server) -> Fut + Send + Sync>;

pub(crate) struct RetryAction<Fut, T, E> {
    token: String,
    server: Server,
    user: Arc<dyn WorkspaceUser>,
    builder: Builder<Fut>,
    phantom: PhantomData<(T, E)>,
}

impl<Fut, T, E> RetryAction<Fut, T, E> {
    pub(crate) fn new<F>(server: Server, user: Arc<dyn WorkspaceUser>, builder: F) -> Self
    where
        Fut: Future<Output = Result<T, E>> + Send + Sync + 'static,
        F: Fn(String, Server) -> Fut + Send + Sync + 'static,
    {
        let token = user.token().unwrap_or("".to_owned());
        Self {
            token,
            server,
            user,
            builder: Box::new(builder),
            phantom: PhantomData,
        }
    }
}

impl<Fut, T, E> Action for RetryAction<Fut, T, E>
where
    Fut: Future<Output = Result<T, E>> + Send + Sync + 'static,
    T: Send + Sync + 'static,
    E: Send + Sync + 'static,
{
    type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send + Sync>>;
    type Item = T;
    type Error = E;

    fn run(&mut self) -> Self::Future {
        let fut = (self.builder)(self.token.clone(), self.server.clone());
        Box::pin(RetryActionFut { fut: Box::pin(fut) })
    }
}

#[pin_project]
struct RetryActionFut<T, E> {
    #[pin]
    fut: Pin<Box<dyn Future<Output = Result<T, E>> + Send + Sync>>,
}

impl<T, E> Future for RetryActionFut<T, E>
where
    T: Send + Sync + 'static,
    E: Send + Sync + 'static,
{
    type Output = Result<T, E>;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let mut this = self.project();
        this.fut.as_mut().poll(cx)
    }
}
