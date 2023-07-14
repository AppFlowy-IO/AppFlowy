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
#[cfg(debug_assertions)]
pub(crate) async fn run_initial_drop(client: &Client) {
  // let sql = include_str!("migrations/initial/initial_down.sql");
  let sql = r#"DROP TABLE IF EXISTS af_user;
DROP TABLE IF EXISTS af_workspace;
DROP TABLE IF EXISTS af_user_profile;
DROP TABLE IF EXISTS af_collab;
DROP VIEW IF EXISTS af_collab_state;
DROP TABLE IF EXISTS af_collab_snapshot;
DROP TABLE IF EXISTS af_collab_statistics;

DROP TRIGGER IF EXISTS create_af_user_profile_trigger ON af_user_profile CASCADE;
DROP FUNCTION IF EXISTS create_af_user_profile_trigger_func;

DROP TRIGGER IF EXISTS create_af_workspace_trigger ON af_workspace CASCADE;
DROP FUNCTION IF EXISTS create_af_workspace_trigger_func;

DROP TRIGGER IF EXISTS af_collab_insert_trigger ON af_collab CASCADE;
DROP FUNCTION IF EXISTS increment_af_collab_update_count;

DROP TRIGGER IF EXISTS af_collab_snapshot_update_edit_count_trigger ON af_collab_snapshot;
DROP FUNCTION IF EXISTS af_collab_snapshot_update_edit_count;

DROP TRIGGER IF EXISTS check_and_delete_snapshots_trigger ON af_collab_snapshot CASCADE;
DROP FUNCTION IF EXISTS check_and_delete_snapshots;
"#;
  client.batch_execute(sql).await.unwrap();
  client
    .batch_execute("DROP TABLE IF EXISTS af_migration_history")
    .await
    .unwrap();
}

#[cfg(test)]
mod tests {
  use tokio_postgres::NoTls;

  use flowy_server_config::supabase_config::PostgresConfiguration;

  use crate::supabase::migration::run_initial_drop;

  // ‼️‼️‼️ Warning: this test will create a table in the database
  #[tokio::test]
  async fn test_postgres_db() -> Result<(), anyhow::Error> {
    if dotenv::from_filename(".env.test").is_err() {
      return Ok(());
    }

    let configuration = PostgresConfiguration::from_env().unwrap();
    let mut config = tokio_postgres::Config::new();
    config
      .host(&configuration.url)
      .user(&configuration.user_name)
      .password(&configuration.password)
      .port(configuration.port);

    // Using the https://docs.rs/postgres-openssl/latest/postgres_openssl/ to enable tls connection.
    let (client, connection) = config.connect(NoTls).await?;
    tokio::spawn(async move {
      if let Err(e) = connection.await {
        tracing::error!("postgres db connection error: {}", e);
      }
    });

    #[cfg(debug_assertions)]
    {
      run_initial_drop(&client).await;
    }
    Ok(())
  }
}
