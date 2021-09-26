use crate::{
    entities::doc::{DocTable, DOC_TABLE},
    sqlx_ext::SqlBuilder,
};

use flowy_net::errors::ServerError;

use sqlx::postgres::PgArguments;
use uuid::Uuid;

pub struct NewDocSqlBuilder {
    table: DocTable,
}

impl NewDocSqlBuilder {
    pub fn new(id: Uuid) -> Self {
        let table = DocTable {
            id,
            data: "".to_owned(),
            rev_id: 0,
        };
        Self { table }
    }

    pub fn data(mut self, data: String) -> Self {
        self.table.data = data;
        self
    }

    pub fn build(self) -> Result<(String, PgArguments), ServerError> {
        let (sql, args) = SqlBuilder::create(DOC_TABLE)
            .add_arg("id", self.table.id)
            .add_arg("data", self.table.data)
            .add_arg("rev_id", self.table.rev_id)
            .build()?;

        Ok((sql, args))
    }
}
