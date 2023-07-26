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
      if !report.applied_migrations().is_empty() {
        tracing::info!("Run postgres db migration: {:?}", report);
      }
      Ok(())
    },
    Err(e) => Err(anyhow::anyhow!("postgres db migration error: {}", e)),
  }
}
