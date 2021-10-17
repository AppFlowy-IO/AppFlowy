use crate::{
    entities::view::{RepeatedView, View},
    errors::WorkspaceError,
    sql_tables::view::{ViewTable, ViewTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{view_table, view_table::dsl},
    SqliteConnection,
};

pub struct ViewTableSql {}

impl ViewTableSql {
    pub(crate) fn create_view(view_table: ViewTable, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        match diesel_record_count!(view_table, &view_table.id, conn) {
            0 => diesel_insert_table!(view_table, &view_table, conn),
            _ => {
                let changeset = ViewTableChangeset::from_table(view_table);
                diesel_update_table!(view_table, changeset, conn)
            },
        }
        Ok(())
    }

    pub(crate) fn read_view(view_id: &str, conn: &SqliteConnection) -> Result<ViewTable, WorkspaceError> {
        // https://docs.diesel.rs/diesel/query_builder/struct.UpdateStatement.html
        // let mut filter =
        // dsl::view_table.filter(view_table::id.eq(view_id)).into_boxed();
        // if let Some(is_trash) = is_trash {
        //     filter = filter.filter(view_table::is_trash.eq(is_trash));
        // }
        // let repeated_view = filter.first::<ViewTable>(conn)?;
        let view_table = dsl::view_table
            .filter(view_table::id.eq(view_id))
            .first::<ViewTable>(conn)?;

        Ok(view_table)
    }

    // belong_to_id will be the app_id or view_id.
    pub(crate) fn read_views(belong_to_id: &str, conn: &SqliteConnection) -> Result<RepeatedView, WorkspaceError> {
        let view_tables = dsl::view_table
            .filter(view_table::belong_to_id.eq(belong_to_id))
            .into_boxed()
            .load::<ViewTable>(conn)?;

        let views = view_tables
            .into_iter()
            .map(|view_table| view_table.into())
            .collect::<Vec<View>>();

        Ok(RepeatedView { items: views })
    }

    pub(crate) fn update_view(changeset: ViewTableChangeset, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_update_table!(view_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn delete_view(view_id: &str, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_delete_table!(view_table, view_id, conn);
        Ok(())
    }
}

// pub(crate) fn read_views(
//     belong_to_id: &str,
//     is_trash: Option<bool>,
//     conn: &SqliteConnection,
// ) -> Result<RepeatedView, WorkspaceError> {
//     let views = dsl::view_table
//         .inner_join(trash_table::dsl::trash_table.on(trash_id.ne(view_table::
// id)))         .filter(view_table::belong_to_id.eq(belong_to_id))
//         .select((
//             view_table::id,
//             view_table::belong_to_id,
//             view_table::name,
//             view_table::desc,
//             view_table::modified_time,
//             view_table::create_time,
//             view_table::thumbnail,
//             view_table::view_type,
//             view_table::version,
//         ))
//         .load(conn)?
//         .into_iter()
//         .map(
//             |(id, belong_to_id, name, desc, create_time, modified_time,
// thumbnail, view_type, version)| {                 ViewTable {
//                     id,
//                     belong_to_id,
//                     name,
//                     desc,
//                     modified_time,
//                     create_time,
//                     thumbnail,
//                     view_type,
//                     version,
//                     is_trash: false,
//                 }
//                 .into()
//             },
//         )
//         .collect::<Vec<View>>();
//
//     Ok(RepeatedView { items: views })
// }
