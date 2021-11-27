use std::{io, thread};

use tokio::runtime;

pub mod ready;

pub fn tokio_default_runtime() -> io::Result<tokio::runtime::Runtime> {
    runtime::Builder::new_multi_thread()
        .thread_name("flowy-rt")
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
