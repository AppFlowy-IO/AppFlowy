use std::sync::Arc;

use crate::utils::cache::AnyTypeCache;

pub type CalculationsByFieldIdCache = Arc<AnyTypeCache<String>>;
