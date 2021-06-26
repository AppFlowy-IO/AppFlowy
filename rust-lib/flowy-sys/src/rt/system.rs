use crate::{
    module::{Command, Module},
    request::FlowyRequest,
    response::FlowyResponse,
    rt::Runtime,
};
use futures_core::{future::LocalBoxFuture, ready, task::Context};
use futures_util::{future, pin_mut};
use std::{cell::RefCell, future::Future, io, sync::Arc};
use tokio::{
    macros::support::{Pin, Poll},
    sync::{
        mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender},
        oneshot,
    },
};

thread_local!(
    static CURRENT: RefCell<Option<Arc<FlowySystem>>> = RefCell::new(None);
);

pub struct FlowySystem {
    resp_tx: UnboundedSender<FlowyResponse>,
    modules: Vec<Module>,
}

impl FlowySystem {
    pub fn construct<F>(module_factory: F) -> SystemRunner
    where
        F: FnOnce(UnboundedSender<FlowyResponse>) -> Vec<Module>,
    {
        let runtime = Runtime::new().unwrap();
        let (resp_tx, mut resp_rx) = unbounded_channel::<FlowyResponse>();
        let (stop_tx, stop_rx) = oneshot::channel();
        let controller = SystemController { resp_rx, stop_tx };
        runtime.spawn(controller);

        let mut system = Self {
            resp_tx: resp_tx.clone(),
            modules: vec![],
        };

        let factory = module_factory(resp_tx.clone());
        factory.into_iter().for_each(|m| {
            runtime.spawn(m);
            // system.add_module(m);
        });

        FlowySystem::set_current(system);

        let runner = SystemRunner { rt: runtime, stop_rx };
        runner
    }

    pub fn handle_command(&self, cmd: Command, request: FlowyRequest) {
        self.modules.iter().for_each(|m| {
            if m.can_handle(&cmd) {
                m.handle(request.clone());
            }
        })
    }

    pub fn add_module(&mut self, module: Module) { self.modules.push(module); }

    #[doc(hidden)]
    pub fn set_current(sys: FlowySystem) {
        CURRENT.with(|cell| {
            *cell.borrow_mut() = Some(Arc::new(sys));
        })
    }

    pub fn current() -> Arc<FlowySystem> {
        CURRENT.with(|cell| match *cell.borrow() {
            Some(ref sys) => sys.clone(),
            None => panic!("System is not running"),
        })
    }

    pub(crate) fn resp_tx(&self) -> UnboundedSender<FlowyResponse> { self.resp_tx.clone() }
}

struct SystemController {
    resp_rx: UnboundedReceiver<FlowyResponse>,
    stop_tx: oneshot::Sender<i32>,
}

impl Future for SystemController {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.resp_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(resp) => {
                    // FFI
                    println!("Receive response: {:?}", resp);
                },
            }
        }
    }
}

pub struct SystemRunner {
    rt: Runtime,
    stop_rx: oneshot::Receiver<i32>,
}

impl SystemRunner {
    pub fn run(self) -> io::Result<()> {
        let SystemRunner { rt, stop_rx } = self;
        match rt.block_on(stop_rx) {
            Ok(code) => {
                if code != 0 {
                    Err(io::Error::new(
                        io::ErrorKind::Other,
                        format!("Non-zero exit code: {}", code),
                    ))
                } else {
                    Ok(())
                }
            },
            Err(e) => Err(io::Error::new(io::ErrorKind::Other, e)),
        }
    }

    pub fn spawn<F>(self, future: F) -> Self
    where
        F: Future<Output = ()> + 'static,
    {
        self.rt.spawn(future);
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    pub async fn hello_service() -> String { "hello".to_string() }

    #[test]
    fn test() {
        let command = "Hello".to_string();

        FlowySystem::construct(|tx| {
            vec![
                Module::new(tx.clone()).event(command.clone(), hello_service),
                // Module::new(tx.clone()).event(command.clone(), hello_service),
            ]
        })
        .spawn(async {
            let request = FlowyRequest::new(command.clone());
            FlowySystem::current().handle_command(command, request);
        })
        .run()
        .unwrap();
    }
}
