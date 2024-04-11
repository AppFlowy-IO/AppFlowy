use parking_lot::RwLock;
use std::sync::Arc;

use crate::utils::cache::AnyTypeCache;

pub type CellCache = Arc<RwLock<AnyTypeCache<u64>>>;
