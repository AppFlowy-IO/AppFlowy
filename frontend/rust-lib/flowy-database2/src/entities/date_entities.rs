use crate::entities::CellIdPB;
use flowy_derive::ProtoBuf;

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateCellDataPB {
  #[pb(index = 1)]
  pub date: String,

  #[pb(index = 2)]
  pub time: String,

  #[pb(index = 3)]
  pub timestamp: i64,

  #[pb(index = 4)]
  pub include_time: bool,
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateChangesetPB {
  #[pb(index = 1)]
  pub cell_path: CellIdPB,

  #[pb(index = 2, one_of)]
  pub date: Option<String>,

  #[pb(index = 3, one_of)]
  pub time: Option<String>,

  #[pb(index = 4, one_of)]
  pub include_time: Option<bool>,

  #[pb(index = 5)]
  pub is_utc: bool,
}
