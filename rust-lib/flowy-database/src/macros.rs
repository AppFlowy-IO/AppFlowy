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
