use crate::revision::SettingRevision;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};

#[allow(dead_code)]
pub fn gen_grid_view_id() -> String {
    nanoid!(6)
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridViewRevision {
    pub view_id: String,

    pub grid_id: String,

    pub setting: SettingRevision,

    // For the moment, we just use the order returned from the GridRevision
    #[allow(dead_code)]
    #[serde(skip, rename = "row")]
    pub row_orders: Vec<RowOrderRevision>,
}

impl GridViewRevision {
    pub fn new(grid_id: String, view_id: String) -> Self {
        GridViewRevision {
            view_id,
            grid_id,
            setting: Default::default(),
            row_orders: vec![],
        }
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RowOrderRevision {
    pub row_id: String,
}
