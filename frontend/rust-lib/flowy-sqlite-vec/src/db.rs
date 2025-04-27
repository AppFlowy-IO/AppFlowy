use crate::init_sqlite_vector_extension;
use crate::migration::init_sqlite_with_migrations;
use anyhow::{Context, Result};
use rusqlite::{params, Connection, ToSql};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use uuid::Uuid;
use zerocopy::IntoBytes;

pub struct VectorSqliteDB {
  conn: Arc<Mutex<Connection>>,
}

unsafe impl Send for VectorSqliteDB {}
unsafe impl Sync for VectorSqliteDB {}

impl VectorSqliteDB {
  pub fn new(root: PathBuf) -> Result<Self> {
    init_sqlite_vector_extension();

    let db_path = root.join("vector.db");
    let conn = Arc::new(Mutex::new(init_sqlite_with_migrations(db_path.as_path())?));
    Ok(Self { conn })
  }

  pub async fn select_collabs_fragment_ids(
    &self,
    object_ids: &[String],
  ) -> Result<HashMap<Uuid, Vec<String>>> {
    if object_ids.is_empty() {
      return Ok(HashMap::new());
    }

    let placeholders = std::iter::repeat("?")
      .take(object_ids.len())
      .collect::<Vec<_>>()
      .join(", ");

    let sql = format!(
      "SELECT fragment_id, oid \
             FROM chunk_embeddings_info \
             WHERE oid IN ({})",
      placeholders
    );

    // Prepare the statement
    let conn = self.conn.lock().await;
    let mut stmt = conn
      .prepare(&sql)
      .context("Preparing select_collabs_fragment_ids")?;

    // Convert &[String] to a Vec<&dyn ToSql> so we can bind them all at once.
    let params: Vec<&dyn ToSql> = object_ids.iter().map(|s| s as &dyn ToSql).collect();
    let mut rows = stmt
      .query(params.as_slice())
      .context("Executing select_collabs_fragment_ids query")?;

    // Collect into a HashMap<Uuid, Vec<fragment_id>>
    let mut map: HashMap<Uuid, Vec<String>> = HashMap::new();
    while let Some(row) = rows.next()? {
      let fragment_id: String = row.get(0)?;
      let oid_str: String = row.get(1)?;
      let oid = Uuid::parse_str(&oid_str)
        .map_err(|e| anyhow::anyhow!("Invalid UUID `{}` in DB: {}", oid_str, e))?;

      map.entry(oid).or_default().push(fragment_id);
    }

    Ok(map)
  }

  pub async fn upsert_collabs_embeddings(
    &self,
    oid: &str,
    fragments: Vec<EmbeddedChunk>,
  ) -> Result<()> {
    if fragments.is_empty() {
      return Ok(());
    }

    // no `mut` needed here
    let mut conn = self.conn.lock().await;
    let tx = conn.transaction().context("Starting transaction")?;

    // build a Vec<&str> and repeat("?"), not '?'
    let fragment_ids: Vec<&str> = fragments.iter().map(|f| f.fragment_id.as_str()).collect();
    let placeholders = std::iter::repeat("?")
      .take(fragment_ids.len())
      .collect::<Vec<_>>()
      .join(", ");

    let delete_sql = format!(
      "DELETE FROM chunk_embeddings_info WHERE oid = ?1 AND fragment_id NOT IN ({})",
      placeholders
    );

    // first bind oid, then each fragment_id, as a &[&dyn ToSql]
    let mut delete_params: Vec<&dyn ToSql> = Vec::with_capacity(1 + fragment_ids.len());
    delete_params.push(&oid);
    delete_params.extend(fragment_ids.iter().map(|s| s as &dyn ToSql));

    tx.execute(&delete_sql, delete_params.as_slice())
      .context("Deleting stale fragments")?;

    {
      // drop this Statement before committing
      let mut insert_stmt = tx.prepare(
        "INSERT OR REPLACE INTO chunk_embeddings_info
             (fragment_id, oid, content_type, content, metadata,fragment_index, embedder_type)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
      )?;

      for fragment in fragments {
        if fragment.content.is_none() {
          continue;
        }

        insert_stmt.execute(rusqlite::params![
          fragment.fragment_id,
          oid,
          fragment.content_type,
          fragment.content.unwrap_or_default(),
          fragment.metadata,
          fragment.fragment_index,
          fragment.embedder_type,
        ])?;

        // get the inserted embed_id from  chunk_embeddings_info

        if let Some(embeddings) = fragment.embeddings {
          let mut select_stmt =
            tx.prepare("SELECT rowid FROM chunk_embeddings_info WHERE fragment_id = ?1")?;
          let embed_id: i64 =
            select_stmt.query_row(rusqlite::params![fragment.fragment_id], |row| row.get(0))?;

          let mut embed_stmt =
            tx.prepare("INSERT INTO embeddings_768_v0(rowid, embedding) VALUES (?, ?)")?;
          embed_stmt.execute(rusqlite::params![embed_id, embeddings.as_bytes()])?;
        }
      }
    } // insert_stmt dropped here

    tx.commit().context("Committing transaction")?;
    Ok(())
  }

  pub async fn search(&self, query: &[f32], top_k: i32) -> Result<Vec<SearchResult>> {
    let query_blob: &[u8] = query.as_bytes();
    let sql = "\
            SELECT info.oid, info.content, info.metadata
              FROM embeddings_768_v0 AS emb
         JOIN chunk_embeddings_info AS info
               ON emb.rowid = info.embed_id
             WHERE emb.embedding MATCH ?
               AND k = ?
        ";

    let conn = self.conn.lock().await;
    let mut stmt = conn.prepare(sql).context("Preparing search statement")?;

    // 3) bind the vector blob and the limit
    let rows = stmt
      .query_map(params![query_blob, top_k], |row| {
        Ok(SearchResult {
          oid: row.get(0)?,
          content: row.get(1)?,
          metadata: row.get(2)?,
        })
      })
      .context("Executing search query")?;

    // 4) collect into Vec<SearchResult>
    let mut results = Vec::with_capacity(top_k as usize);
    for row in rows {
      results.push(row?);
    }
    Ok(results)
  }
}

#[derive(Debug, Clone)]
pub struct EmbeddedChunk {
  pub fragment_id: String,
  pub object_id: String,
  pub content_type: i32,
  pub content: Option<String>,
  pub metadata: Option<String>,
  pub fragment_index: i32,
  pub embedder_type: i32,
  pub embeddings: Option<Vec<f32>>,
}

#[derive(Debug, Clone)]
pub struct SearchResult {
  pub oid: String,
  pub content: String,
  pub metadata: Option<String>,
}
