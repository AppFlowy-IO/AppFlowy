use crate::entities::doc::Revision;
use diesel::sql_types::Integer;
use flowy_database::schema::op_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "op_table"]
#[primary_key(doc_id)]
pub(crate) struct OpTable {
    pub(crate) doc_id: String,
    pub(crate) base_rev_id: i64,
    pub(crate) rev_id: i64,
    pub(crate) data: Vec<u8>,
    pub(crate) md5: String,
    pub(crate) state: OpState,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum OpState {
    Local = 0,
    Acked = 1,
}

impl std::default::Default for OpState {
    fn default() -> Self { OpState::Local }
}

impl std::convert::From<i32> for OpState {
    fn from(value: i32) -> Self {
        match value {
            0 => OpState::Local,
            1 => OpState::Acked,
            o => {
                log::error!("Unsupported view type {}, fallback to ViewType::Docs", o);
                OpState::Local
            },
        }
    }
}

impl OpState {
    pub fn value(&self) -> i32 { *self as i32 }
}

impl_sql_integer_expression!(OpState);

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "op_table"]
#[primary_key(doc_id)]
pub(crate) struct OpChangeset {
    pub(crate) doc_id: String,
    pub(crate) rev_id: i64,
    pub(crate) state: Option<OpState>,
}

impl std::convert::Into<OpTable> for Revision {
    fn into(self) -> OpTable {
        OpTable {
            doc_id: self.doc_id,
            base_rev_id: self.base_rev_id,
            rev_id: self.rev_id,
            data: self.delta,
            md5: self.md5,
            state: OpState::Local,
        }
    }
}
