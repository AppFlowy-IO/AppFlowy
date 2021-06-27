use crate::{
    module::{Event, Module},
    request::EventRequest,
    response::EventResponse,
    rt::runtime::Runtime,
};
use futures_core::{ready, task::Context};

use crate::error::{InternalError, SystemError};
use std::{cell::RefCell, collections::HashMap, future::Future, io, sync::Arc};
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

#[derive(Debug)]
pub enum SystemCommand {
    Exit(i8),
    EventResponse(EventResponse),
}

pub struct FlowySystem {
    sys_tx: UnboundedSender<SystemCommand>,
    forward_map: HashMap<Event, UnboundedSender<EventRequest>>,
}

impl FlowySystem {
    pub fn construct<F>(module_factory: F, response_tx: Option<UnboundedSender<EventResponse>>) -> SystemRunner
    where
        F: FnOnce(UnboundedSender<SystemCommand>) -> Vec<Module>,
    {
        let runtime = Runtime::new().unwrap();
        let (sys_tx, sys_rx) = unbounded_channel::<SystemCommand>();
        let (stop_tx, stop_rx) = oneshot::channel();

        runtime.spawn(SystemController {
            stop_tx: Some(stop_tx),
            sys_rx,
            response_tx,
        });

        let mut system = Self {
            sys_tx: sys_tx.clone(),
            forward_map: HashMap::default(),
        };

        let factory = module_factory(sys_tx.clone());
        factory.into_iter().for_each(|m| {
            system.forward_map.extend(m.forward_map());
            runtime.spawn(m);
        });

        FlowySystem::set_current(system);
        let runner = SystemRunner { rt: runtime, stop_rx };
        runner
    }

    pub fn sink(&self, event: Event, request: EventRequest) -> Result<(), SystemError> {
        log::debug!("Sink event: {}", event);
        let _ = self.forward_map.get(&event)?.send(request)?;
        Ok(())
    }

    pub fn request_tx(&self, event: Event) -> Option<UnboundedSender<EventRequest>> {
        match self.forward_map.get(&event) {
            Some(tx) => Some(tx.clone()),
            None => None,
        }
    }

    pub fn stop(&self) {
        match self.sys_tx.send(SystemCommand::Exit(0)) {
            Ok(_) => {},
            Err(e) => {
                log::error!("Stop system error: {}", e);
            },
        }
    }

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
}

struct SystemController {
    stop_tx: Option<oneshot::Sender<i8>>,
    sys_rx: UnboundedReceiver<SystemCommand>,
    response_tx: Option<UnboundedSender<EventResponse>>,
}

impl Future for SystemController {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.sys_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(cmd) => match cmd {
                    SystemCommand::Exit(code) => {
                        if let Some(tx) = self.stop_tx.take() {
                            let _ = tx.send(code);
                        }
                    },
                    SystemCommand::EventResponse(resp) => {
                        log::debug!("Response: {:?}", resp);
                        if let Some(tx) = &self.response_tx {
                            match tx.send(resp) {
                                Ok(_) => {},
                                Err(e) => {
                                    log::error!("Response tx send fail: {:?}", e);
                                },
                            }
                        }
                    },
                },
            }
        }
    }
}

pub struct SystemRunner {
    rt: Runtime,
    stop_rx: oneshot::Receiver<i8>,
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
