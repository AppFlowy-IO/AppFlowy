use diesel::sql_types::Integer;
use flowy_database::schema::op_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "op_table"]
#[primary_key(rev)]
pub(crate) struct OpTable {
    pub(crate) base_rev: i64,
    pub(crate) rev: i64,
    pub(crate) data: Vec<u8>,
    pub(crate) md5: String,
    pub(crate) state: OpState,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum OpState {
    Local   = 0,
    Sending = 1,
    Acked   = 2,
}

impl std::default::Default for OpState {
    fn default() -> Self { OpState::Local }
}

impl std::convert::From<i32> for OpState {
    fn from(value: i32) -> Self {
        match value {
            0 => OpState::Local,
            1 => OpState::Sending,
            2 => OpState::Acked,
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
#[primary_key(rev)]
pub(crate) struct OpChangeset {
    pub(crate) rev: i64,
    pub(crate) state: Option<OpState>,
}
