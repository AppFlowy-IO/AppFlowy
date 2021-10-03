use pin_project::pin_project;
use std::{
    future::Future,
    iter::{IntoIterator, Iterator},
    pin::Pin,
    task::{Context, Poll},
};
use tokio::time::{sleep_until, Duration, Instant, Sleep};

#[pin_project(project = RetryStateProj)]
enum RetryState<A>
where
    A: Action,
{
    Running(#[pin] A::Future),
    Sleeping(#[pin] Sleep),
}

impl<A: Action> RetryState<A> {
    fn poll(self: Pin<&mut Self>, cx: &mut Context) -> RetryFuturePoll<A> {
        match self.project() {
            RetryStateProj::Running(future) => RetryFuturePoll::Running(future.poll(cx)),
            RetryStateProj::Sleeping(future) => RetryFuturePoll::Sleeping(future.poll(cx)),
        }
    }
}

enum RetryFuturePoll<A>
where
    A: Action,
{
    Running(Poll<Result<A::Item, A::Error>>),
    Sleeping(Poll<()>),
}

/// Future that drives multiple attempts at an action via a retry strategy.
#[pin_project]
pub struct Retry<I, A>
where
    I: Iterator<Item = Duration>,
    A: Action,
{
    #[pin]
    retry_if: RetryIf<I, A, fn(&A::Error) -> bool>,
}

impl<I, A> Retry<I, A>
where
    I: Iterator<Item = Duration>,
    A: Action,
{
    pub fn spawn<T: IntoIterator<IntoIter = I, Item = Duration>>(strategy: T, action: A) -> Retry<I, A> {
        Retry {
            retry_if: RetryIf::spawn(strategy, action, (|_| true) as fn(&A::Error) -> bool),
        }
    }
}

impl<I, A> Future for Retry<I, A>
where
    I: Iterator<Item = Duration>,
    A: Action,
{
    type Output = Result<A::Item, A::Error>;

    fn poll(self: Pin<&mut Self>, cx: &mut Context) -> Poll<Self::Output> {
        let this = self.project();
        this.retry_if.poll(cx)
    }
}

/// Future that drives multiple attempts at an action via a retry strategy.
/// Retries are only attempted if the `Error` returned by the future satisfies a
/// given condition.
#[pin_project]
pub struct RetryIf<I, A, C>
where
    I: Iterator<Item = Duration>,
    A: Action,
    C: Condition<A::Error>,
{
    strategy: I,
    #[pin]
    state: RetryState<A>,
    action: A,
    condition: C,
}

impl<I, A, C> RetryIf<I, A, C>
where
    I: Iterator<Item = Duration>,
    A: Action,
    C: Condition<A::Error>,
{
    pub fn spawn<T: IntoIterator<IntoIter = I, Item = Duration>>(
        strategy: T,
        mut action: A,
        condition: C,
    ) -> RetryIf<I, A, C> {
        RetryIf {
            strategy: strategy.into_iter(),
            state: RetryState::Running(action.run()),
            action,
            condition,
        }
    }

    fn attempt(mut self: Pin<&mut Self>, cx: &mut Context) -> Poll<Result<A::Item, A::Error>> {
        let future = {
            let this = self.as_mut().project();
            this.action.run()
        };
        self.as_mut().project().state.set(RetryState::Running(future));
        self.poll(cx)
    }

    fn retry(
        mut self: Pin<&mut Self>,
        err: A::Error,
        cx: &mut Context,
    ) -> Result<Poll<Result<A::Item, A::Error>>, A::Error> {
        match self.as_mut().project().strategy.next() {
            None => Err(err),
            Some(duration) => {
                let deadline = Instant::now() + duration;
                let future = sleep_until(deadline);
                self.as_mut().project().state.set(RetryState::Sleeping(future));
                Ok(self.poll(cx))
            },
        }
    }
}

impl<I, A, C> Future for RetryIf<I, A, C>
where
    I: Iterator<Item = Duration>,
    A: Action,
    C: Condition<A::Error>,
{
    type Output = Result<A::Item, A::Error>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context) -> Poll<Self::Output> {
        match self.as_mut().project().state.poll(cx) {
            RetryFuturePoll::Running(poll_result) => match poll_result {
                Poll::Ready(Ok(ok)) => Poll::Ready(Ok(ok)),
                Poll::Pending => Poll::Pending,
                Poll::Ready(Err(err)) => {
                    if self.as_mut().project().condition.should_retry(&err) {
                        match self.retry(err, cx) {
                            Ok(poll) => poll,
                            Err(err) => Poll::Ready(Err(err)),
                        }
                    } else {
                        Poll::Ready(Err(err))
                    }
                },
            },
            RetryFuturePoll::Sleeping(poll_result) => match poll_result {
                Poll::Pending => Poll::Pending,
                Poll::Ready(_) => self.attempt(cx),
            },
        }
    }
}

/// An action can be run multiple times and produces a future.
pub trait Action {
    type Future: Future<Output = Result<Self::Item, Self::Error>>;
    type Item;
    type Error;

    fn run(&mut self) -> Self::Future;
}

impl<R, E, T: Future<Output = Result<R, E>>, F: FnMut() -> T> Action for F {
    type Future = T;
    type Item = R;
    type Error = E;

    fn run(&mut self) -> Self::Future { self() }
}

pub trait Condition<E> {
    fn should_retry(&mut self, error: &E) -> bool;
}

impl<E, F: FnMut(&E) -> bool> Condition<E> for F {
    fn should_retry(&mut self, error: &E) -> bool { self(error) }
}
