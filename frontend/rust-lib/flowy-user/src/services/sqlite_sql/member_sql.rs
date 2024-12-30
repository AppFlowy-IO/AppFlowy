use diesel::{insert_into, RunQueryDsl};
use flowy_error::FlowyResult;

use flowy_sqlite::schema::workspace_members_table;

use flowy_sqlite::schema::workspace_members_table::dsl;
use flowy_sqlite::{query_dsl::*, DBConnection, ExpressionMethods};

#[derive(Queryable, Insertable, AsChangeset, Debug)]
#[diesel(table_name = workspace_members_table)]
#[diesel(primary_key(email, workspace_id))]
pub struct WorkspaceMemberTable {
  pub email: String,
  pub role: i32,
  pub name: String,
  pub avatar_url: Option<String>,
  pub uid: i64,
  pub workspace_id: String,
  pub updated_at: chrono::NaiveDateTime,
}

pub fn upsert_workspace_member<T: Into<WorkspaceMemberTable>>(
  mut conn: DBConnection,
  member: T,
) -> FlowyResult<()> {
  let member = member.into();

  insert_into(workspace_members_table::table)
    .values(&member)
    .on_conflict((
      workspace_members_table::email,
      workspace_members_table::workspace_id,
    ))
    .do_update()
    .set(&member)
    .execute(&mut conn)?;

  Ok(())
}

pub fn select_workspace_member(
  mut conn: DBConnection,
  workspace_id: &str,
  uid: i64,
) -> FlowyResult<WorkspaceMemberTable> {
  let member = dsl::workspace_members_table
    .filter(workspace_members_table::workspace_id.eq(workspace_id))
    .filter(workspace_members_table::uid.eq(uid))
    .first::<WorkspaceMemberTable>(&mut conn)?;

  Ok(member)
}
