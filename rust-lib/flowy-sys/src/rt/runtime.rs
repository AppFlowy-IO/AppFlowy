use std::{future::Future, io, thread};
use thread_id;
use tokio::{runtime, task::LocalSet};

#[derive(Debug)]
pub struct Runtime {
    local: LocalSet,
    rt: runtime::Runtime,
}

impl Runtime {
    pub fn new() -> io::Result<Runtime> {
        let rt = runtime::Builder::new_multi_thread()
            .thread_name("flowy-sys")
            .enable_io()
            .enable_time()
            .on_thread_start(move || {
                log::trace!(
                    "{:?} thread started: thread_id= {}",
                    thread::current(),
                    thread_id::get()
                );
            })
            .on_thread_stop(move || {
                log::trace!(
                    "{:?} thread stopping: thread_id= {}",
                    thread::current(),
                    thread_id::get(),
                );
            })
            .build()?;

        Ok(Runtime {
            rt,
            local: LocalSet::new(),
        })
    }

    pub fn spawn<F>(&self, future: F) -> &Self
    where
        F: Future<Output = ()> + 'static,
    {
        self.local.spawn_local(future);
        self
    }

    pub fn block_on<F>(&self, f: F) -> F::Output
    where
        F: Future + 'static,
    {
        self.local.block_on(&self.rt, f)
    }
}
