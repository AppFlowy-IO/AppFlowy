#[rustfmt::skip]
/*
diesel master support on_conflict on sqlite but not 1.4.7 version. Workaround for this

match dsl::workspace_table
    .filter(workspace_table::id.eq(table.id.clone()))
    .count()
    .get_result(conn)
    .unwrap_or(0)
{
    0 => diesel::insert_into(workspace_table::table).values(table)
                    .on_conflict(workspace_table::id)
                    .do_update()
                    .set(WorkspaceTableChangeset::from_table(workspace_table))
                    .execute(conn)?,
    _ => {
        let changeset = WorkspaceTableChangeset::from_table(table);
        let filter = dsl::workspace_table.filter(workspace_table::id.eq(changeset.id.clone()));
        diesel::update(filter).set(changeset).execute(conn)?;
    },
}

is equivalent to:

match diesel_record_count!(workspace_table, &table.id, conn) {
    0 => diesel_insert_table!(workspace_table, table, conn),
    _ => diesel_update_table!(workspace_table, WorkspaceTableChangeset::from_table(table), &*conn),
}
*/

#[macro_export]
macro_rules! diesel_insert_table {
    (
        $table_name:ident,
        $table:expr,
        $connection:expr
    ) => {
        {
        let _ = diesel::insert_into($table_name::table)
                    .values($table.clone())
                    // .on_conflict($table_name::dsl::id)
                    // .do_update()
                    // .set(WorkspaceTableChangeset::from_table(workspace_table))
                    .execute($connection)?;
        }
    };
}

#[macro_export]
macro_rules! diesel_record_count {
    (
        $table_name:ident,
        $id:expr,
        $connection:expr
    ) => {
        $table_name::dsl::$table_name
            .filter($table_name::dsl::id.eq($id.clone()))
            .count()
            .get_result($connection)
            .unwrap_or(0);
    };
}

#[macro_export]
macro_rules! diesel_update_table {
    (
        $table_name:ident,
        $changeset:expr,
        $connection:expr
    ) => {{
        let filter = $table_name::dsl::$table_name.filter($table_name::dsl::id.eq($changeset.id.clone()));
        let affected_row = diesel::update(filter).set($changeset).execute($connection)?;
        debug_assert_eq!(affected_row, 1);
    }};
}

#[macro_export]
macro_rules! diesel_delete_table {
    (
        $table_name:ident,
        $id:ident,
        $connection:ident
    ) => {
        let filter = $table_name::dsl::$table_name.filter($table_name::dsl::id.eq($id));
        let affected_row = diesel::delete(filter).execute(&*$connection)?;
        debug_assert_eq!(affected_row, 1);
    };
}
