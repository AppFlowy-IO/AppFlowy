pub use async_trait;
pub mod box_any;

#[cfg(not(target_arch = "wasm32"))]
pub mod file_util;

#[cfg(feature = "compression")]
pub mod compression;

if_native! {
  pub mod future {
   pub use crate::native::future::*;
  }
}

if_wasm! {
  pub mod future {
   pub use crate::wasm::future::*;
  }
}

pub mod ref_map;
pub mod util;
pub mod validator_fn;

mod native;
pub mod priority_task;
mod wasm;
