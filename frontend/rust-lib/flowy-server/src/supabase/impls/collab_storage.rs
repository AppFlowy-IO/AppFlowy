use std::sync::Arc;

use anyhow::Error;
use appflowy_integrate::{CollabObject, MsgId, RemoteCollabStorage};
use deadpool_postgres::GenericClient;

use lib_infra::async_trait::async_trait;

use crate::supabase::PostgresServer;

pub struct CollabStorageImpl {
  server: Arc<PostgresServer>,
}

impl CollabStorageImpl {
  pub fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

#[async_trait]
impl RemoteCollabStorage for CollabStorageImpl {
  async fn get_all_updates(&self, object_id: &str) -> Result<Vec<Vec<u8>>, Error> {
    let client = self.server.get_pg_client().await.recv().await?;
    let stmt = client
      .prepare_cached("SELECT value FROM af_collab WHERE oid = $1 ORDER BY oid ASC")
      .await?;
    Ok(client.query(&stmt, &[&object_id]).await.map(|rows| {
      rows
        .into_iter()
        .map(|row| row.get::<_, Vec<u8>>("value"))
        .collect()
    })?)
  }

  async fn send_update(
    &self,
    object: &CollabObject,
    _id: MsgId,
    update: Vec<u8>,
  ) -> Result<(), Error> {
    let client = self.server.get_pg_client().await.recv().await?;
    let stmt = client
      .prepare_cached("INSERT INTO af_collab (oid, name, value) VALUES ($1, $2, $3)")
      .await?;
    client
      .execute(&stmt, &[&object.id, &object.name, &update])
      .await?;
    Ok(())
  }
}
