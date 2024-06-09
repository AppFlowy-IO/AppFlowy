use parking_lot::RwLock;
use std::sync::Arc;

use crate::utils::cache::AnyTypeCache;

pub type CalculationsByFieldIdCache = Arc<RwLock<AnyTypeCache<String>>>;
