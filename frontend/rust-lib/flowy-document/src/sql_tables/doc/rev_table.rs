use diesel::sql_types::Integer;
use flowy_database::schema::rev_table;

use flowy_document_infra::util::md5;
use lib_ot::revision::{RevId, RevState, RevType, Revision};

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rev_table"]
pub(crate) struct RevTable {
    id: i32,
    pub(crate) doc_id: String,
    pub(crate) base_rev_id: i64,
    pub(crate) rev_id: i64,
    pub(crate) data: Vec<u8>,
    pub(crate) state: RevTableState,
    pub(crate) ty: RevTableType,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum RevTableState {
    Local = 0,
    Acked = 1,
}

impl std::default::Default for RevTableState {
    fn default() -> Self { RevTableState::Local }
}

impl std::convert::From<i32> for RevTableState {
    fn from(value: i32) -> Self {
        match value {
            0 => RevTableState::Local,
            1 => RevTableState::Acked,
            o => {
                log::error!("Unsupported rev state {}, fallback to RevState::Local", o);
                RevTableState::Local
            },
        }
    }
}

impl RevTableState {
    pub fn value(&self) -> i32 { *self as i32 }
}
impl_sql_integer_expression!(RevTableState);

impl std::convert::From<RevTableState> for RevState {
    fn from(s: RevTableState) -> Self {
        match s {
            RevTableState::Local => RevState::Local,
            RevTableState::Acked => RevState::Acked,
        }
    }
}

impl std::convert::From<RevState> for RevTableState {
    fn from(s: RevState) -> Self {
        match s {
            RevState::Local => RevTableState::Local,
            RevState::Acked => RevTableState::Acked,
        }
    }
}

pub(crate) fn mk_revision_from_table(user_id: &str, table: RevTable) -> Revision {
    let md5 = md5(&table.data);
    Revision {
        base_rev_id: table.base_rev_id,
        rev_id: table.rev_id,
        delta_data: table.data,
        md5,
        doc_id: table.doc_id,
        ty: table.ty.into(),
        user_id: user_id.to_owned(),
    }
}

impl std::convert::From<RevType> for RevTableType {
    fn from(ty: RevType) -> Self {
        match ty {
            RevType::Local => RevTableType::Local,
            RevType::Remote => RevTableType::Remote,
        }
    }
}

impl std::convert::From<RevTableType> for RevType {
    fn from(ty: RevTableType) -> Self {
        match ty {
            RevTableType::Local => RevType::Local,
            RevTableType::Remote => RevType::Remote,
        }
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

#[allow(dead_code)]
pub(crate) struct RevChangeset {
    pub(crate) doc_id: String,
    pub(crate) rev_id: RevId,
    pub(crate) state: RevTableState,
}
