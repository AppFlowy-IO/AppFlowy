use crate::entities::doc::{RevType, Revision};
use diesel::sql_types::Integer;
use flowy_database::schema::rev_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rev_table"]
#[primary_key(doc_id)]
pub(crate) struct RevTable {
    pub(crate) doc_id: String,
    pub(crate) base_rev_id: i64,
    pub(crate) rev_id: i64,
    pub(crate) data: Vec<u8>,
    pub(crate) md5: String,
    pub(crate) state: RevState,
    pub(crate) ty: RevTableType,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum RevState {
    Local = 0,
    Acked = 1,
}

impl std::default::Default for RevState {
    fn default() -> Self { RevState::Local }
}

impl std::convert::From<i32> for RevState {
    fn from(value: i32) -> Self {
        match value {
            0 => RevState::Local,
            1 => RevState::Acked,
            o => {
                log::error!("Unsupported rev state {}, fallback to RevState::Local", o);
                RevState::Local
            },
        }
    }
}
impl RevState {
    pub fn value(&self) -> i32 { *self as i32 }
}
impl_sql_integer_expression!(RevState);

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

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "rev_table"]
#[primary_key(doc_id)]
pub(crate) struct RevChangeset {
    pub(crate) doc_id: String,
    pub(crate) rev_id: i64,
    pub(crate) state: Option<RevState>,
}

impl std::convert::Into<RevTable> for Revision {
    fn into(self) -> RevTable {
        RevTable {
            doc_id: self.doc_id,
            base_rev_id: self.base_rev_id,
            rev_id: self.rev_id,
            data: self.delta,
            md5: self.md5,
            state: RevState::Local,
            ty: rev_ty_to_rev_state(self.ty),
        }
    }
}

fn rev_ty_to_rev_state(ty: RevType) -> RevTableType {
    match ty {
        RevType::Local => RevTableType::Local,
        RevType::Remote => RevTableType::Remote,
    }
}
