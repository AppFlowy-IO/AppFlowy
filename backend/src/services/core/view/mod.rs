#![allow(clippy::module_inception)]
mod controller;
pub mod persistence;
pub mod router;

pub(crate) use controller::*;
