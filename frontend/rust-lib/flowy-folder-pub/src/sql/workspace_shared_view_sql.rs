use diesel::{RunQueryDsl, insert_into};
use flowy_error::FlowyResult;
use flowy_sqlite::schema::workspace_shared_view;
use flowy_sqlite::schema::workspace_shared_view::dsl;
use flowy_sqlite::{DBConnection, ExpressionMethods, prelude::*};

#[derive(Queryable, Insertable, AsChangeset, Debug, Clone)]
#[diesel(table_name = workspace_shared_view)]
#[diesel(primary_key(uid, workspace_id, view_id))]
pub struct WorkspaceSharedViewTable {
  pub uid: i64,
  pub workspace_id: String,
  pub view_id: String,
  pub permission_id: i32,
  pub created_at: Option<chrono::NaiveDateTime>,
}

pub fn upsert_workspace_shared_view<T: Into<WorkspaceSharedViewTable>>(
  conn: &mut SqliteConnection,
  shared_view: T,
) -> FlowyResult<()> {
  let shared_view = shared_view.into();

  insert_into(workspace_shared_view::table)
    .values(&shared_view)
    .on_conflict((
      workspace_shared_view::uid,
      workspace_shared_view::workspace_id,
      workspace_shared_view::view_id,
    ))
    .do_update()
    .set(&shared_view)
    .execute(conn)?;

  Ok(())
}

pub fn select_workspace_shared_view(
  mut conn: DBConnection,
  workspace_id: &str,
  view_id: &str,
  uid: i64,
) -> FlowyResult<WorkspaceSharedViewTable> {
  let shared_view = dsl::workspace_shared_view
    .filter(workspace_shared_view::workspace_id.eq(workspace_id))
    .filter(workspace_shared_view::view_id.eq(view_id))
    .filter(workspace_shared_view::uid.eq(uid))
    .first::<WorkspaceSharedViewTable>(&mut conn)?;

  Ok(shared_view)
}

pub fn select_all_workspace_shared_views(
  mut conn: DBConnection,
  workspace_id: &str,
  uid: i64,
) -> FlowyResult<Vec<WorkspaceSharedViewTable>> {
  let shared_views = dsl::workspace_shared_view
    .filter(workspace_shared_view::workspace_id.eq(workspace_id))
    .filter(workspace_shared_view::uid.eq(uid))
    .load::<WorkspaceSharedViewTable>(&mut conn)?;
  Ok(shared_views)
}

pub fn upsert_workspace_shared_views<T: Into<WorkspaceSharedViewTable> + Clone>(
  conn: &mut SqliteConnection,
  _workspace_id: &str,
  _uid: i64,
  shared_views: &[T],
) -> FlowyResult<()> {
  for shared_view in shared_views.iter().cloned() {
    let shared_view: WorkspaceSharedViewTable = shared_view.into();
    insert_into(workspace_shared_view::table)
      .values(&shared_view)
      .on_conflict((
        workspace_shared_view::uid,
        workspace_shared_view::workspace_id,
        workspace_shared_view::view_id,
      ))
      .do_update()
      .set(&shared_view)
      .execute(conn)?;
  }
  Ok(())
}

/// Removes all workspace_shared_view items for the given workspace_id and uid, then inserts the provided new items.
pub fn replace_all_workspace_shared_views<T: Into<WorkspaceSharedViewTable> + Clone>(
  conn: &mut SqliteConnection,
  workspace_id: &str,
  uid: i64,
  new_shared_views: &[T],
) -> FlowyResult<()> {
  // Remove all existing items for the workspace_id and uid
  delete(
    workspace_shared_view::table
      .filter(workspace_shared_view::workspace_id.eq(workspace_id))
      .filter(workspace_shared_view::uid.eq(uid)),
  )
  .execute(conn)?;

  upsert_workspace_shared_views(conn, workspace_id, uid, new_shared_views)?;

  Ok(())
}
