use crate::revision::SettingRevision;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct GridViewRevision {
    pub view_id: String,

    pub grid_id: String,

    pub setting: SettingRevision,
    // TODO: Save the rows' order.
    // For the moment, we just use the order returned from the GridRevision
    // #[serde(rename = "row")]
    // pub row_orders: Vec<RowOrderRevision>,
}

// #[derive(Debug, Clone, Default, Serialize, Deserialize)]
// pub struct RowOrderRevision {
//     pub row_id: String,
// }
