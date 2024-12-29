use diesel::upsert::excluded;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::{
  diesel, insert_into,
  query_dsl::*,
  schema::{af_collab_metadata, af_collab_metadata::dsl},
  DBConnection, ExpressionMethods, Identifiable, Insertable, Queryable,
};
use std::collections::HashMap;

#[derive(Queryable, Insertable, Identifiable)]
#[diesel(table_name = af_collab_metadata)]
#[diesel(primary_key(object_id))]
pub struct AFCollabMetadata {
  pub object_id: String,
  pub updated_at: i64,
  pub prev_sync_state_vector: Vec<u8>,
  pub collab_type: i32,
}

pub fn batch_insert_collab_metadata(
  mut conn: DBConnection,
  new_metadata: &[AFCollabMetadata],
) -> FlowyResult<()> {
  conn.immediate_transaction(|conn| {
    for metadata in new_metadata {
      let _ = insert_into(af_collab_metadata::table)
        .values(metadata)
        .on_conflict(af_collab_metadata::object_id)
        .do_update()
        .set((
          af_collab_metadata::updated_at.eq(excluded(af_collab_metadata::updated_at)),
          af_collab_metadata::prev_sync_state_vector
            .eq(excluded(af_collab_metadata::prev_sync_state_vector)),
        ))
        .execute(conn)?;
    }
    Ok::<(), FlowyError>(())
  })?;

  Ok(())
}

pub fn batch_select_collab_metadata(
  mut conn: DBConnection,
  object_ids: &[String],
) -> FlowyResult<HashMap<String, AFCollabMetadata>> {
  let metadata = dsl::af_collab_metadata
    .filter(af_collab_metadata::object_id.eq_any(object_ids))
    .load::<AFCollabMetadata>(&mut conn)?
    .into_iter()
    .map(|m| (m.object_id.clone(), m))
    .collect();
  Ok(metadata)
}
