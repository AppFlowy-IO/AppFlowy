use crate::{
    entities::doc::{RevId, RevType, Revision},
    services::util::md5,
};
use diesel::sql_types::Integer;
use flowy_database::schema::rev_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rev_table"]
pub(crate) struct RevTable {
    id: i32,
    pub(crate) doc_id: String,
    pub(crate) base_rev_id: i64,
    pub(crate) rev_id: i64,
    pub(crate) data: Vec<u8>,
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

impl std::convert::Into<Revision> for RevTable {
    fn into(self) -> Revision {
        let md5 = md5(&self.data);
        Revision {
            base_rev_id: self.base_rev_id,
            rev_id: self.rev_id,
            delta_data: self.data,
            md5,
            doc_id: self.doc_id,
            ty: self.ty.into(),
        }
    }
}

impl std::convert::Into<RevTableType> for RevType {
    fn into(self) -> RevTableType {
        match self {
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
    pub(crate) state: RevState,
}
