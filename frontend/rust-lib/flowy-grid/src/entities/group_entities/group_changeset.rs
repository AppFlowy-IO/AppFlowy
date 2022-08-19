use crate::entities::{GroupPB, InsertedRowPB, RowPB};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use std::fmt::Formatter;

#[derive(Debug, Default, ProtoBuf)]
pub struct GroupRowsChangesetPB {
    #[pb(index = 1)]
    pub group_id: String,

    #[pb(index = 2)]
    pub inserted_rows: Vec<InsertedRowPB>,

    #[pb(index = 3)]
    pub deleted_rows: Vec<String>,

    #[pb(index = 4)]
    pub updated_rows: Vec<RowPB>,
}

impl std::fmt::Display for GroupRowsChangesetPB {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        for inserted_row in &self.inserted_rows {
            let _ = f.write_fmt(format_args!(
                "Insert: {} row at {:?}",
                inserted_row.row.id, inserted_row.index
            ))?;
        }

        for deleted_row in &self.deleted_rows {
            let _ = f.write_fmt(format_args!("Delete: {} row", deleted_row))?;
        }

        Ok(())
    }
}

impl GroupRowsChangesetPB {
    pub fn is_empty(&self) -> bool {
        self.inserted_rows.is_empty() && self.deleted_rows.is_empty() && self.updated_rows.is_empty()
    }
    pub fn insert(group_id: String, inserted_rows: Vec<InsertedRowPB>) -> Self {
        Self {
            group_id,
            inserted_rows,
            ..Default::default()
        }
    }

    pub fn delete(group_id: String, deleted_rows: Vec<String>) -> Self {
        Self {
            group_id,
            deleted_rows,
            ..Default::default()
        }
    }

    pub fn update(group_id: String, updated_rows: Vec<RowPB>) -> Self {
        Self {
            group_id,
            updated_rows,
            ..Default::default()
        }
    }
}
#[derive(Debug, Default, ProtoBuf)]
pub struct MoveGroupPayloadPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub from_group_id: String,

    #[pb(index = 3)]
    pub to_group_id: String,
}

pub struct MoveGroupParams {
    pub view_id: String,
    pub from_group_id: String,
    pub to_group_id: String,
}

impl TryInto<MoveGroupParams> for MoveGroupPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<MoveGroupParams, Self::Error> {
        let view_id = NotEmptyStr::parse(self.view_id)
            .map_err(|_| ErrorCode::GridViewIdIsEmpty)?
            .0;
        let from_group_id = NotEmptyStr::parse(self.from_group_id)
            .map_err(|_| ErrorCode::GroupIdIsEmpty)?
            .0;
        let to_group_id = NotEmptyStr::parse(self.to_group_id)
            .map_err(|_| ErrorCode::GroupIdIsEmpty)?
            .0;
        Ok(MoveGroupParams {
            view_id,
            from_group_id,
            to_group_id,
        })
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GroupsChangesetPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub inserted_groups: Vec<GroupPB>,

    #[pb(index = 3)]
    pub deleted_groups: Vec<String>,
}

impl GroupsChangesetPB {}
