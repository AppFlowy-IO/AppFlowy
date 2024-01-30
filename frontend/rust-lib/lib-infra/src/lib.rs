pub use async_trait;
pub mod box_any;

#[cfg(feature = "compression")]
pub mod compression;

if_native! {
  mod native;
  pub mod file_util;
  pub mod future {
   pub use crate::native::future::*;
  }
}

if_wasm! {
  mod wasm;
  pub mod future {
  pub use crate::wasm::future::*;
  }
}

pub mod priority_task;
pub mod ref_map;
pub mod util;
pub mod validator_fn;
