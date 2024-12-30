use std::sync::Arc;

use crate::utils::cache::AnyTypeCache;

pub type CellCache = Arc<AnyTypeCache<u64>>;
