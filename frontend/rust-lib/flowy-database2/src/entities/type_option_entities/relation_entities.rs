use flowy_derive::ProtoBuf;

use crate::entities::CellIdPB;
use crate::services::field::{RelationCellData, RelationTypeOption};

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RelationCellDataPB {
  #[pb(index = 1)]
  pub row_ids: Vec<String>,
}

impl From<RelationCellData> for RelationCellDataPB {
  fn from(data: RelationCellData) -> Self {
    Self {
      row_ids: data.row_ids.into_iter().map(Into::into).collect(),
    }
  }
}

impl From<RelationCellDataPB> for RelationCellData {
  fn from(data: RelationCellDataPB) -> Self {
    Self {
      row_ids: data.row_ids.into_iter().map(Into::into).collect(),
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RelationCellChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub cell_id: CellIdPB,

  #[pb(index = 3)]
  pub inserted_row_ids: Vec<String>,

  #[pb(index = 4)]
  pub removed_row_ids: Vec<String>,
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct RelationTypeOptionPB {
  #[pb(index = 1)]
  pub database_id: String,
}

impl From<RelationTypeOption> for RelationTypeOptionPB {
  fn from(value: RelationTypeOption) -> Self {
    RelationTypeOptionPB {
      database_id: value.database_id,
    }
  }
}

impl From<RelationTypeOptionPB> for RelationTypeOption {
  fn from(value: RelationTypeOptionPB) -> Self {
    RelationTypeOption {
      database_id: value.database_id,
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RelatedRowDataPB {
  #[pb(index = 1)]
  pub row_id: String,

  #[pb(index = 2)]
  pub name: String,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedRelatedRowDataPB {
  #[pb(index = 1)]
  pub rows: Vec<RelatedRowDataPB>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct GetRelatedRowDataPB {
  #[pb(index = 1)]
  pub database_id: String,

  #[pb(index = 2)]
  pub row_ids: Vec<String>,
}
