use refinery::embed_migrations;
use tokio_postgres::Client;

embed_migrations!("./src/supabase/migrations");

const AF_MIGRATION_HISTORY: &str = "af_migration_history";

pub(crate) async fn run_migrations(client: &mut Client) -> Result<(), anyhow::Error> {
  match migrations::runner()
    .set_migration_table_name(AF_MIGRATION_HISTORY)
    .run_async(client)
    .await
  {
    Ok(report) => {
      tracing::trace!("postgres db migration success: {:?}", report);
      Ok(())
    },
    Err(e) => {
      tracing::error!("postgres db migration error: {}", e);
      Err(anyhow::anyhow!("postgres db migration error: {}", e))
    },
  }
}

/// Drop all tables and dependencies defined in the v1_initial_up.sql.
/// Be careful when using this function. It will drop all tables and dependencies.
/// Mostly used for testing.
#[allow(dead_code)]
pub(crate) async fn run_initial_drop(client: &Client) {
  let sql = include_str!("./migrations/initial/initial_down.sql");
  client.batch_execute(sql).await.unwrap();
}
