use std::{io, thread};
use tokio::runtime;

pub type FlowyRuntime = tokio::runtime::Runtime;

pub fn tokio_default_runtime() -> io::Result<FlowyRuntime> {
    runtime::Builder::new_multi_thread()
        .thread_name("dispatch-rt")
        .enable_io()
        .enable_time()
        .on_thread_start(move || {
            tracing::trace!(
                "{:?} thread started: thread_id= {}",
                thread::current(),
                thread_id::get()
            );
        })
        .on_thread_stop(move || {
            tracing::trace!(
                "{:?} thread stopping: thread_id= {}",
                thread::current(),
                thread_id::get(),
            );
        })
        .build()
}
