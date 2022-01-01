use crate::services::doc::revision::RevisionRecord;
use bytes::Bytes;
use diesel::sql_types::Integer;
use flowy_collaboration::{
    entities::revision::{RevId, RevType, Revision, RevisionState},
    util::md5,
};
use flowy_database::schema::rev_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rev_table"]
pub(crate) struct RevisionTable {
    id: i32,
    pub(crate) doc_id: String,
    pub(crate) base_rev_id: i64,
    pub(crate) rev_id: i64,
    pub(crate) data: Vec<u8>,
    pub(crate) state: RevisionTableState,
    pub(crate) ty: RevTableType, // Deprecated
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum RevisionTableState {
    Local = 0,
    Ack   = 1,
}

impl std::default::Default for RevisionTableState {
    fn default() -> Self { RevisionTableState::Local }
}

impl std::convert::From<i32> for RevisionTableState {
    fn from(value: i32) -> Self {
        match value {
            0 => RevisionTableState::Local,
            1 => RevisionTableState::Ack,
            o => {
                log::error!("Unsupported rev state {}, fallback to RevState::Local", o);
                RevisionTableState::Local
            },
        }
    }
}

impl RevisionTableState {
    pub fn value(&self) -> i32 { *self as i32 }
}
impl_sql_integer_expression!(RevisionTableState);

impl std::convert::From<RevisionTableState> for RevisionState {
    fn from(s: RevisionTableState) -> Self {
        match s {
            RevisionTableState::Local => RevisionState::Local,
            RevisionTableState::Ack => RevisionState::Ack,
        }
    }
}

impl std::convert::From<RevisionState> for RevisionTableState {
    fn from(s: RevisionState) -> Self {
        match s {
            RevisionState::Local => RevisionTableState::Local,
            RevisionState::Ack => RevisionTableState::Ack,
        }
    }
}

pub(crate) fn mk_revision_record_from_table(user_id: &str, table: RevisionTable) -> RevisionRecord {
    let md5 = md5(&table.data);
    let revision = Revision::new(
        &table.doc_id,
        table.base_rev_id,
        table.rev_id,
        Bytes::from(table.data),
        &user_id,
        md5,
    );
    RevisionRecord {
        revision,
        state: table.state.into(),
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum RevTableType {
    Local  = 0,
    Remote = 1,
}

impl std::default::Default for RevTableType {
    fn default() -> Self { RevTableType::Local }
}

impl std::convert::From<i32> for RevTableType {
    fn from(value: i32) -> Self {
        match value {
            0 => RevTableType::Local,
            1 => RevTableType::Remote,
            o => {
                log::error!("Unsupported rev type {}, fallback to RevTableType::Local", o);
                RevTableType::Local
            },
        }
    }
}
impl RevTableType {
    pub fn value(&self) -> i32 { *self as i32 }
}
impl_sql_integer_expression!(RevTableType);

impl std::convert::From<RevType> for RevTableType {
    fn from(ty: RevType) -> Self {
        match ty {
            RevType::DeprecatedLocal => RevTableType::Local,
            RevType::DeprecatedRemote => RevTableType::Remote,
        }
    }
}

impl std::convert::From<RevTableType> for RevType {
    fn from(ty: RevTableType) -> Self {
        match ty {
            RevTableType::Local => RevType::DeprecatedLocal,
            RevTableType::Remote => RevType::DeprecatedRemote,
        }
    }
}

pub struct RevisionChangeset {
    pub(crate) doc_id: String,
    pub(crate) rev_id: RevId,
    pub(crate) state: RevisionTableState,
}
