use diesel::{RunQueryDsl, delete, insert_into};
use flowy_error::FlowyResult;
use flowy_sqlite::schema::workspace_shared_user;
use flowy_sqlite::schema::workspace_shared_user::dsl;
use flowy_sqlite::{DBConnection, ExpressionMethods, SqliteConnection, prelude::*};

#[derive(Queryable, Insertable, AsChangeset, Debug, Clone)]
#[diesel(table_name = workspace_shared_user)]
#[diesel(primary_key(workspace_id, view_id, email))]
pub struct WorkspaceSharedUserTable {
  pub workspace_id: String,
  pub view_id: String,
  pub email: String,
  pub name: String,
  pub avatar_url: String,
  pub role: i32,
  pub access_level: i32,
}

impl WorkspaceSharedUserTable {
  pub fn new(
    workspace_id: String,
    view_id: String,
    email: String,
    name: String,
    avatar_url: String,
    role: i32,
    access_level: i32,
  ) -> Self {
    Self {
      workspace_id,
      view_id,
      email,
      name,
      avatar_url,
      role,
      access_level,
    }
  }
}

pub fn upsert_workspace_shared_user<T: Into<WorkspaceSharedUserTable>>(
  conn: &mut SqliteConnection,
  shared_user: T,
) -> FlowyResult<()> {
  let shared_user = shared_user.into();

  insert_into(workspace_shared_user::table)
    .values(&shared_user)
    .on_conflict((
      workspace_shared_user::workspace_id,
      workspace_shared_user::view_id,
      workspace_shared_user::email,
    ))
    .do_update()
    .set(&shared_user)
    .execute(conn)?;

  Ok(())
}

pub fn select_workspace_shared_user(
  mut conn: DBConnection,
  workspace_id: &str,
  view_id: &str,
  email: &str,
) -> FlowyResult<WorkspaceSharedUserTable> {
  let shared_user = dsl::workspace_shared_user
    .filter(workspace_shared_user::workspace_id.eq(workspace_id))
    .filter(workspace_shared_user::view_id.eq(view_id))
    .filter(workspace_shared_user::email.eq(email))
    .first::<WorkspaceSharedUserTable>(&mut conn)?;

  Ok(shared_user)
}

pub fn select_all_workspace_shared_users(
  mut conn: DBConnection,
  workspace_id: &str,
  view_id: &str,
) -> FlowyResult<Vec<WorkspaceSharedUserTable>> {
  let shared_users = dsl::workspace_shared_user
    .filter(workspace_shared_user::workspace_id.eq(workspace_id))
    .filter(workspace_shared_user::view_id.eq(view_id))
    .load::<WorkspaceSharedUserTable>(&mut conn)?;
  Ok(shared_users)
}

pub fn select_all_workspace_shared_users_by_workspace(
  mut conn: DBConnection,
  workspace_id: &str,
) -> FlowyResult<Vec<WorkspaceSharedUserTable>> {
  let shared_users = dsl::workspace_shared_user
    .filter(workspace_shared_user::workspace_id.eq(workspace_id))
    .load::<WorkspaceSharedUserTable>(&mut conn)?;
  Ok(shared_users)
}

pub fn upsert_workspace_shared_users<T: Into<WorkspaceSharedUserTable> + Clone>(
  conn: &mut SqliteConnection,
  _workspace_id: &str,
  _view_id: &str,
  shared_users: &[T],
) -> FlowyResult<()> {
  for shared_user in shared_users.iter().cloned() {
    let shared_user: WorkspaceSharedUserTable = shared_user.into();
    insert_into(workspace_shared_user::table)
      .values(&shared_user)
      .on_conflict((
        workspace_shared_user::workspace_id,
        workspace_shared_user::view_id,
        workspace_shared_user::email,
      ))
      .do_update()
      .set(&shared_user)
      .execute(conn)?;
  }
  Ok(())
}

/// Removes all workspace_shared_user items for the given workspace_id and view_id, then inserts the provided new items.
pub fn replace_all_workspace_shared_users<T: Into<WorkspaceSharedUserTable> + Clone>(
  conn: &mut SqliteConnection,
  workspace_id: &str,
  view_id: &str,
  new_shared_users: &[T],
) -> FlowyResult<()> {
  // Remove all existing items for the workspace_id and view_id
  delete(
    workspace_shared_user::table
      .filter(workspace_shared_user::workspace_id.eq(workspace_id))
      .filter(workspace_shared_user::view_id.eq(view_id)),
  )
  .execute(conn)?;

  upsert_workspace_shared_users(conn, workspace_id, view_id, new_shared_users)?;

  Ok(())
}

/// Removes a specific workspace_shared_user by workspace_id, view_id, and email.
pub fn delete_workspace_shared_user(
  conn: &mut SqliteConnection,
  workspace_id: &str,
  view_id: &str,
  email: &str,
) -> FlowyResult<()> {
  delete(
    workspace_shared_user::table
      .filter(workspace_shared_user::workspace_id.eq(workspace_id))
      .filter(workspace_shared_user::view_id.eq(view_id))
      .filter(workspace_shared_user::email.eq(email)),
  )
  .execute(conn)?;

  Ok(())
}

/// Removes all workspace_shared_user items for the given workspace_id.
pub fn delete_all_workspace_shared_users_by_workspace(
  conn: &mut SqliteConnection,
  workspace_id: &str,
) -> FlowyResult<()> {
  delete(workspace_shared_user::table.filter(workspace_shared_user::workspace_id.eq(workspace_id)))
    .execute(conn)?;

  Ok(())
}
