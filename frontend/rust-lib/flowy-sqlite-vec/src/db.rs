use crate::entities::{
  EmbeddedContent, PendingIndexedCollab, SqliteEmbeddedDocument, SqliteEmbeddedFragment,
};
use crate::init_sqlite_vector_extension;
use crate::migration::init_sqlite_with_migrations;
use anyhow::{Context, Result};
use flowy_ai_pub::entities::{EmbeddedChunk, SearchResult};
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use rusqlite::{ToSql, params};
use serde_json::Value;
use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use tracing::{trace, warn};
use uuid::Uuid;
use zerocopy::IntoBytes;

pub struct VectorSqliteDB {
  pool: Pool<SqliteConnectionManager>,
}

impl VectorSqliteDB {
  pub fn new(root: PathBuf) -> Result<Self> {
    let db_path = root.join("vector.db");

    // Setup the connection manager with the database path
    let manager = SqliteConnectionManager::file(db_path);

    // Initialize SQLite extensions and settings in each new connection
    let manager = manager.with_init(|_| {
      init_sqlite_vector_extension();
      Ok(())
    });

    // Create the connection pool
    let pool = Pool::builder()
      .max_size(10) // Adjust based on your needs
      .build(manager)
      .context("Failed to create connection pool")?;

    // Ensure database is migrated
    let mut conn = pool
      .get()
      .context("Failed to get connection for migration")?;
    init_sqlite_with_migrations(&mut conn)?;

    Ok(Self { pool })
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
      "SELECT fragment_id, object_id FROM af_collab_embeddings WHERE object_id IN ({})",
      placeholders
    );

    let conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;
    let mut stmt = conn
      .prepare(&sql)
      .context("Preparing select_collabs_fragment_ids")?;

    let params: Vec<&dyn ToSql> = object_ids.iter().map(|s| s as &dyn ToSql).collect();
    let mut rows = stmt
      .query(params.as_slice())
      .context("Executing select_collabs_fragment_ids")?;

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

  pub async fn delete_collab(&self, workspace_id: &str, object_id: &str) -> Result<()> {
    let mut conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;
    let tx = conn
      .transaction()
      .context("Starting delete_collab transaction")?;
    tx.execute(
      "DELETE FROM af_collab_embeddings
               WHERE workspace_id = ?1
                 AND object_id    = ?2",
      rusqlite::params![workspace_id, object_id],
    )
    .context("Deleting collab embeddings")?;

    tx.commit()
      .context("Committing delete_collab transaction")?;
    Ok(())
  }

  pub async fn select_all_embedded_content(
    &self,
    workspace_id: &str,
    rag_ids: &[String],
    limit: usize,
  ) -> Result<Vec<EmbeddedContent>> {
    let conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;

    // Build SQL query based on whether rag_ids are provided
    let (sql, params) = if rag_ids.is_empty() {
      // No rag_ids provided, select all content for workspace
      let sql =
        "SELECT object_id, content FROM af_collab_embeddings WHERE workspace_id = ? LIMIT ?";
      let params: Vec<&dyn ToSql> = vec![&workspace_id, &limit];
      (sql.to_string(), params)
    } else {
      // Filter by provided rag_ids
      let placeholders = std::iter::repeat("?")
        .take(rag_ids.len())
        .collect::<Vec<_>>()
        .join(", ");

      let sql = format!(
        "SELECT object_id, content FROM af_collab_embeddings WHERE workspace_id = ? AND object_id IN ({}) LIMIT ?",
        placeholders
      );

      let mut params: Vec<&dyn ToSql> = vec![&workspace_id];
      params.extend(rag_ids.iter().map(|id| id as &dyn ToSql));
      params.push(&limit);
      (sql, params)
    };

    let mut stmt = conn.prepare(&sql)?;
    let mut rows = stmt.query(params.as_slice())?;

    let mut contents = Vec::new();
    while let Some(row) = rows.next()? {
      let object_id: String = row.get(0)?;
      let content: String = row.get(1)?;
      contents.push(EmbeddedContent { content, object_id });
    }

    Ok(contents)
  }

  pub async fn select_all_embedded_documents(
    &self,
    workspace_id: &str,
    rag_ids: &[String],
  ) -> Result<Vec<SqliteEmbeddedDocument>> {
    let conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;

    // Build SQL query based on whether rag_ids are provided
    let (sql, params) = if rag_ids.is_empty() {
      // No rag_ids provided, select all documents for workspace
      let sql = "SELECT object_id, content, embedding 
                FROM af_collab_embeddings 
                WHERE workspace_id = ?";
      let params: Vec<&dyn ToSql> = vec![&workspace_id];
      (sql.to_string(), params)
    } else {
      // Filter by provided rag_ids
      let placeholders = std::iter::repeat("?")
        .take(rag_ids.len())
        .collect::<Vec<_>>()
        .join(", ");

      let sql = format!(
        "SELECT object_id, content, embedding 
         FROM af_collab_embeddings 
         WHERE workspace_id = ? AND object_id IN ({})",
        placeholders
      );

      let mut params: Vec<&dyn ToSql> = vec![&workspace_id];
      params.extend(rag_ids.iter().map(|id| id as &dyn ToSql));
      (sql, params)
    };

    let mut stmt = conn.prepare(&sql)?;
    let mut rows = stmt.query(params.as_slice())?;

    // Group results by object_id
    let mut documents_map: HashMap<String, Vec<SqliteEmbeddedFragment>> = HashMap::new();

    while let Some(row) = rows.next()? {
      let object_id: String = row.get(0)?;
      let content: String = row.get(1)?;

      // Convert embedding blob to Vec<f32>
      let embedding_blob: Vec<u8> = row.get(2)?;
      let embeddings = if !embedding_blob.is_empty() {
        // Convert bytes to Vec<f32> - each f32 is 4 bytes
        let mut vec = Vec::with_capacity(embedding_blob.len() / 4);
        for chunk in embedding_blob.chunks_exact(4) {
          if let Ok(array) = chunk.try_into() {
            vec.push(f32::from_le_bytes(array));
          }
        }
        vec
      } else {
        Vec::new()
      };

      // Add fragment to the corresponding object_id
      documents_map
        .entry(object_id)
        .or_default()
        .push(SqliteEmbeddedFragment {
          content,
          embeddings,
        });
    }

    // Convert the map to the required Vec<SqliteEmbeddedDocument>
    let documents = documents_map
      .into_iter()
      .map(|(object_id, fragments)| SqliteEmbeddedDocument {
        workspace_id: workspace_id.to_string(),
        object_id,
        fragments,
      })
      .collect();

    Ok(documents)
  }

  /// Inserts or replaces all of `fragments` for the given (workspace_id, object_id),
  /// deleting anything else in that scope first, and storing the new vector blobs.
  pub async fn upsert_collabs_embeddings(
    &self,
    workspace_id: &str,
    object_id: &str,
    fragments: Vec<EmbeddedChunk>,
  ) -> Result<()> {
    if fragments.is_empty() {
      return Ok(());
    }

    trace!(
      "[VectorStore] workspace:{} upserting {} fragments for {}",
      workspace_id,
      fragments.len(),
      object_id
    );

    let mut conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;
    let tx = conn.transaction().context("Starting transaction")?;

    // 1) Collect new IDs
    let new_ids: Vec<&str> = fragments.iter().map(|f| f.fragment_id.as_str()).collect();

    // 2) Load existing IDs from the DB
    let mut stmt = tx.prepare(
      "SELECT fragment_id
           FROM af_collab_embeddings
          WHERE workspace_id = ?1
            AND object_id    = ?2",
    )?;
    let existing_ids: HashSet<String> = stmt
      .query_map(params![workspace_id, object_id], |row| row.get(0))?
      .collect::<Result<_, _>>()?;
    drop(stmt);

    // 3) Compute which to delete (existing − new)
    let to_delete: Vec<&str> = existing_ids
      .iter()
      .filter_map(|id| {
        if !new_ids.contains(&id.as_str()) {
          Some(id.as_str())
        } else {
          None
        }
      })
      .collect();

    // 4) Delete stale fragments (if any)
    if !to_delete.is_empty() {
      trace!(
        "[VectorStore] Deleting {} {} stale fragments",
        object_id,
        to_delete.len()
      );
      let placeholders = std::iter::repeat("?")
        .take(to_delete.len())
        .collect::<Vec<_>>()
        .join(", ");
      let sql = format!(
        "DELETE FROM af_collab_embeddings
               WHERE workspace_id = ?1
                 AND object_id    = ?2
                 AND fragment_id IN ({})",
        placeholders
      );
      let mut params: Vec<&dyn ToSql> = Vec::with_capacity(2 + to_delete.len());
      params.push(&workspace_id);
      params.push(&object_id);
      params.extend(to_delete.iter().map(|s| s as &dyn ToSql));
      tx.execute(&sql, params.as_slice())
        .context("Deleting stale fragments")?;
    }

    // 5) Insert only the brand-new fragments (new − existing)
    let to_insert: Vec<&EmbeddedChunk> = fragments
      .iter()
      .filter(|f| !existing_ids.contains(&f.fragment_id))
      .collect();

    if !to_insert.is_empty() {
      trace!(
        "[VectorStore] Inserting {} {} new fragments. ids: {:?}",
        object_id,
        to_insert.len(),
        to_insert
          .iter()
          .map(|f| f.fragment_id.as_str())
          .collect::<Vec<_>>()
      );
      let mut insert = tx.prepare(
        "INSERT INTO af_collab_embeddings
               (workspace_id, object_id, fragment_id,
                content_type, content, metadata,
                fragment_index, embedder_type, embedding)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
      )?;

      for frag in to_insert {
        // skip if content missing
        if frag.content.is_none() {
          continue;
        }
        insert
          .execute(rusqlite::params![
            workspace_id,
            object_id,
            &frag.fragment_id,
            frag.content_type,
            frag.content.clone().unwrap_or_default(),
            frag.metadata,
            frag.fragment_index,
            frag.embedder_type,
            frag
              .embeddings
              .as_ref()
              .map(|b| b.as_bytes())
              .unwrap_or(&[]),
          ])
          .context("Inserting new fragment")?;
      }
    }

    tx.commit().context("Committing transaction")?;
    Ok(())
  }

  pub async fn search(
    &self,
    workspace_id: &str,
    object_ids: &[String],
    query: &[f32],
    top_k: i32,
  ) -> Result<Vec<SearchResult>> {
    self
      .search_with_score(workspace_id, object_ids, query, top_k, 0.4)
      .await
  }

  pub async fn search_with_score(
    &self,
    workspace_id: &str,
    object_ids: &[String],
    query: &[f32],
    top_k: i32,
    min_score: f32,
  ) -> Result<Vec<SearchResult>> {
    // clamp min_score to [0,1]
    let min_score = min_score.clamp(0.0, 1.0);
    if object_ids.is_empty() {
      self
        .search_without_object_ids(workspace_id, query, top_k, min_score)
        .await
    } else {
      self
        .search_with_object_ids(workspace_id, object_ids, query, top_k, min_score)
        .await
    }
  }

  async fn search_without_object_ids(
    &self,
    workspace_id: &str,
    query: &[f32],
    top_k: i32,
    min_score: f32,
  ) -> Result<Vec<SearchResult>> {
    trace!(
      "[VectorStore] Searching workspace:{} score:{}",
      workspace_id, min_score
    );
    // distance = 1 - score, so we only want distance <= max_distance
    let max_distance = 1.0 - min_score;
    let query_blob = query.as_bytes();

    let conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;

    // k-NN MATCH without object_id filter
    let sql = "\
          SELECT
            object_id,
            content,
            metadata,
            distance,
            (1.0 - distance) AS score
          FROM af_collab_embeddings
          WHERE embedding MATCH ?
            AND k = ?
            AND workspace_id = ?
            AND distance <= ?
          ORDER BY distance ASC
      ";

    let mut stmt = conn.prepare(sql)?;
    let mut rows = stmt.query(params![
      query_blob,   // MATCH
      top_k,        // number of neighbors
      workspace_id, // workspace filter
      max_distance, // only distances ≤ this
    ])?;

    self.process_search_results(&mut rows)
  }

  async fn search_with_object_ids(
    &self,
    workspace_id: &str,
    object_ids: &[String],
    query: &[f32],
    top_k: i32,
    min_score: f32,
  ) -> Result<Vec<SearchResult>> {
    trace!(
      "[VectorStore] Searching workspace:{} with object_ids: {:?}, score:{}",
      workspace_id, object_ids, min_score
    );
    // distance = 1 - score, so we only want distance <= max_distance
    let max_distance = 1.0 - min_score;
    let query_blob = query.as_bytes();

    let conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;

    // Create placeholders for the IN clause
    let placeholders = std::iter::repeat("?")
      .take(object_ids.len())
      .collect::<Vec<_>>()
      .join(", ");

    // k-NN MATCH with object_id filter
    let sql = format!(
      "SELECT
        object_id,
        content,
        metadata,
        distance,
        (1.0 - distance) AS score
      FROM af_collab_embeddings
      WHERE embedding MATCH ?
        AND k = ?
        AND workspace_id = ?
        AND object_id IN ({})
        AND distance <= ?
      ORDER BY distance ASC",
      placeholders
    );

    let mut stmt = conn.prepare(&sql)?;

    // Create the parameter vector with all params
    let mut query_params: Vec<&dyn ToSql> = Vec::with_capacity(4 + object_ids.len());
    query_params.push(&query_blob as &dyn ToSql);
    query_params.push(&top_k as &dyn ToSql);
    query_params.push(&workspace_id as &dyn ToSql);
    query_params.extend(object_ids.iter().map(|oid| oid as &dyn ToSql));
    query_params.push(&max_distance as &dyn ToSql);
    let mut rows = stmt.query(query_params.as_slice())?;
    self.process_search_results(&mut rows)
  }

  /// Process the query results and convert them to SearchResult objects
  fn process_search_results(&self, rows: &mut rusqlite::Rows) -> Result<Vec<SearchResult>> {
    let mut results = Vec::new();
    while let Some(row) = rows.next()? {
      let oid_str: String = row.get(0)?;
      let oid = match Uuid::parse_str(&oid_str) {
        Ok(u) => u,
        Err(err) => {
          warn!("[VectorStore] Invalid UUID `{}` in DB: {}", oid_str, err);
          continue;
        },
      };
      let content: String = row.get(1)?;
      let metadata = row
        .get::<_, Option<String>>(2)?
        .and_then(|s| serde_json::from_str::<Value>(&s).ok());
      let score: f32 = row.get(4)?;
      trace!(
        "[VectorStore] Found {} embedding record, score: {}",
        oid, score
      );
      results.push(SearchResult {
        oid,
        content,
        metadata,
        score,
      });
    }

    Ok(results)
  }

  pub async fn delete_pending_indexed_collab(
    &self,
    workspace_id: &str,
    object_ids: Vec<String>,
  ) -> Result<()> {
    // Nothing to do if no object_ids provided
    if object_ids.is_empty() {
      return Ok(());
    }

    // Get connection from pool
    let mut conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;
    let tx = conn
      .transaction()
      .context("Starting delete_pending_indexed_collab transaction")?;

    // Build the `IN (?, ?, …)` clause dynamically
    let placeholders = std::iter::repeat("?")
      .take(object_ids.len())
      .collect::<Vec<_>>()
      .join(", ");
    let sql = format!(
      "DELETE FROM af_pending_index_collab WHERE workspace_id = ?1 AND object_id IN ({})",
      placeholders
    );

    // Bind workspace_id as param 1, then each object_id
    let mut query_params: Vec<&dyn ToSql> = Vec::with_capacity(1 + object_ids.len());
    query_params.push(&workspace_id);
    for oid in &object_ids {
      query_params.push(oid as &dyn ToSql);
    }

    // Execute and commit
    tx.execute(&sql, query_params.as_slice())
      .context("Deleting pending indexed collabs")?;
    tx.commit()
      .context("Committing delete_pending_indexed_collab transaction")?;

    Ok(())
  }

  pub async fn queue_pending_indexed_collab(&self, data: PendingIndexedCollab) -> Result<()> {
    self.batch_queue_pending_indexed_collabs(vec![data]).await
  }

  /// Enqueue multiple pending collabs in a single transaction.
  pub async fn batch_queue_pending_indexed_collabs(
    &self,
    data: Vec<PendingIndexedCollab>,
  ) -> Result<()> {
    if data.is_empty() {
      return Ok(());
    }

    // Get connection from pool
    let mut conn = self
      .pool
      .get()
      .context("Failed to get connection from pool")?;
    let tx = conn.transaction().context("Starting transaction")?;

    // prepare INSERT only once
    let mut stmt = tx.prepare(
      "INSERT INTO af_pending_index_collab
               (workspace_id, object_id, collab_type, content)
             VALUES (?1, ?2, ?3, ?4)",
    )?;

    // execute for each item
    for item in data {
      stmt
        .execute(rusqlite::params![
          item.workspace_id,
          item.object_id,
          item.collab_type,
          item.content,
        ])
        .context("Inserting pending collab")?;
    }

    // drop the Statement (releases borrow on tx) then commit
    drop(stmt);
    tx.commit().context("Committing transaction")?;
    Ok(())
  }
}
