#[macro_export]
macro_rules! diesel_update_table {
    (
        $table_name:ident,
        $changeset:ident,
        $connection:ident
    ) => {
        let filter =
            $table_name::dsl::$table_name.filter($table_name::dsl::id.eq($changeset.id.clone()));
        let affected_row = diesel::update(filter)
            .set($changeset)
            .execute(&*$connection)?;
        debug_assert_eq!(affected_row, 1);
    };
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
