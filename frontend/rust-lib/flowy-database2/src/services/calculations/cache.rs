use parking_lot::RwLock;
use std::sync::Arc;

use crate::utils::cache::AnyTypeCache;

pub type CalculationsCache = Arc<RwLock<AnyTypeCache<u64>>>;
