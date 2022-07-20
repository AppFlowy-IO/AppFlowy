use crate::services::persistence::GridDatabase;
use diesel::{ExpressionMethods, QueryDsl, RunQueryDsl};
use flowy_database::{
    prelude::*,
    schema::{grid_block_index_table, grid_block_index_table::dsl},
};
use flowy_error::FlowyResult;
use std::sync::Arc;

/// Allow getting the block id from row id.
pub struct BlockIndexCache {
    database: Arc<dyn GridDatabase>,
}

impl BlockIndexCache {
    pub fn new(database: Arc<dyn GridDatabase>) -> Self {
        Self { database }
    }

    pub fn get_block_id(&self, row_id: &str) -> FlowyResult<String> {
        let conn = self.database.db_connection()?;
        let block_id = dsl::grid_block_index_table
            .filter(grid_block_index_table::row_id.eq(row_id))
            .select(grid_block_index_table::block_id)
            .first::<String>(&*conn)?;

        Ok(block_id)
    }

    pub fn insert(&self, block_id: &str, row_id: &str) -> FlowyResult<()> {
        let conn = self.database.db_connection()?;
        let item = IndexItem {
            row_id: row_id.to_string(),
            block_id: block_id.to_string(),
        };
        let _ = diesel::replace_into(grid_block_index_table::table)
            .values(item)
            .execute(&*conn)?;
        Ok(())
    }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "grid_block_index_table"]
#[primary_key(row_id)]
struct IndexItem {
    row_id: String,
    block_id: String,
}
