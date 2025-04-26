use diesel::sqlite::SqliteConnection;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{collab_embeddings_table, collab_embeddings_table::dsl},
  ExpressionMethods, Identifiable, Insertable, Queryable,
};
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Clone, Debug, Default, Queryable, Insertable, Identifiable)]
#[diesel(table_name = collab_embeddings_table)]
#[diesel(primary_key(fragment_id, oid))]
pub struct CollabEmbeddingsTable {
  pub fragment_id: String,
  pub oid: String,
  pub faiss_id: i32,
  pub content_type: i32,
  pub content: Option<String>,
  pub metadata: Option<String>,
  pub fragment_index: i32,
  pub embedder_type: i32,
}

pub struct Fragment {
  pub fragment_id: String,
  pub content_type: i32,
  pub contents: Option<String>,
  pub metadata: serde_json::Value,
  pub fragment_index: i32,
  pub embedded_type: i16,
}

pub struct FaissFragment {
  pub faiss_id: i32,
  pub data: Fragment,
}

pub fn select_collabs_fragment_ids(
  conn: &mut SqliteConnection,
  object_ids: &[String],
) -> FlowyResult<HashMap<Uuid, Vec<String>>> {
  let rows = dsl::collab_embeddings_table
    .filter(collab_embeddings_table::oid.eq_any(object_ids))
    .select((
      collab_embeddings_table::oid,
      collab_embeddings_table::fragment_id,
    ))
    .load::<(String, String)>(conn)?;

  let mut fragment_ids_by_oid: HashMap<Uuid, Vec<String>> =
    HashMap::with_capacity(object_ids.len());
  for (oid, fragment_id) in rows {
    if let Ok(uuid) = Uuid::parse_str(&oid) {
      fragment_ids_by_oid
        .entry(uuid)
        .or_insert_with(Vec::new)
        .push(fragment_id);
    }
  }
  Ok(fragment_ids_by_oid)
}

pub fn upsert_collab_embeddings(
  conn: &mut SqliteConnection,
  oid: &str,
  fragments: Vec<FaissFragment>,
) -> FlowyResult<()> {
  conn.immediate_transaction(|conn| {
    let fragment_ids = fragments
      .iter()
      .map(|v| v.data.fragment_id.clone())
      .collect::<Vec<_>>();

    //1. delete all fragments where its id is not in the fragments
    diesel::delete(collab_embeddings_table::table)
      .filter(collab_embeddings_table::fragment_id.ne_all(&fragment_ids))
      .execute(conn)?;

    //2. get existing fragments to avoid duplicates
    let existing_fragments = dsl::collab_embeddings_table
      .filter(collab_embeddings_table::oid.eq(oid))
      .filter(collab_embeddings_table::fragment_id.eq_any(&fragment_ids))
      .select(collab_embeddings_table::fragment_id)
      .load::<String>(conn)?;

    let existing_fragment_ids: std::collections::HashSet<String> =
      existing_fragments.into_iter().collect();

    //3. filter out fragments that already exist and prepare new ones
    let new_fragments: Vec<CollabEmbeddingsTable> = fragments
      .iter()
      .filter(|v| !existing_fragment_ids.contains(&v.data.fragment_id))
      .map(|v| CollabEmbeddingsTable {
        fragment_id: v.data.fragment_id.clone(),
        oid: oid.to_string(),
        faiss_id: v.faiss_id,
        content_type: v.data.content_type,
        content: v.data.contents.clone(),
        metadata: Some(serde_json::to_string(&v.data.metadata).unwrap_or_default()),
        fragment_index: v.data.fragment_index,
        embedder_type: v.data.embedded_type as i32,
      })
      .collect();

    //4. insert new fragments if any
    if !new_fragments.is_empty() {
      diesel::insert_into(collab_embeddings_table::table)
        .values(&new_fragments)
        .execute(conn)?;
    }

    Ok::<_, FlowyError>(())
  })?;

  Ok(())
}
