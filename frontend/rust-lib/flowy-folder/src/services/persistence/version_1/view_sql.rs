use crate::{
    entities::{
        trash::{Trash, TrashType},
        view::{RepeatedView, UpdateViewParams, View, ViewDataType},
    },
    errors::FlowyError,
    services::persistence::version_1::app_sql::AppTable,
};
use diesel::sql_types::Integer;
use flowy_database::{
    prelude::*,
    schema::{view_table, view_table::dsl},
    SqliteConnection,
};
use lib_infra::timestamp;

pub struct ViewTableSql();
impl ViewTableSql {
    pub(crate) fn create_view(view: View, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let view_table = ViewTable::new(view);
        match diesel_record_count!(view_table, &view_table.id, conn) {
            0 => diesel_insert_table!(view_table, &view_table, conn),
            _ => {
                let changeset = ViewChangeset::from_table(view_table);
                diesel_update_table!(view_table, changeset, conn)
            }
        }
        Ok(())
    }

    pub(crate) fn read_view(view_id: &str, conn: &SqliteConnection) -> Result<ViewTable, FlowyError> {
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
    pub(crate) fn read_views(belong_to_id: &str, conn: &SqliteConnection) -> Result<Vec<ViewTable>, FlowyError> {
        let view_tables = dsl::view_table
            .filter(view_table::belong_to_id.eq(belong_to_id))
            .order(view_table::create_time.asc())
            .into_boxed()
            .load::<ViewTable>(conn)?;

        Ok(view_tables)
    }

    pub(crate) fn update_view(changeset: ViewChangeset, conn: &SqliteConnection) -> Result<(), FlowyError> {
        diesel_update_table!(view_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn delete_view(view_id: &str, conn: &SqliteConnection) -> Result<(), FlowyError> {
        diesel_delete_table!(view_table, view_id, conn);
        Ok(())
    }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[belongs_to(AppTable, foreign_key = "belong_to_id")]
#[table_name = "view_table"]
pub(crate) struct ViewTable {
    pub id: String,
    pub belong_to_id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub thumbnail: String,
    pub view_type: SqlViewDataType,
    pub version: i64,
    pub is_trash: bool,
}

impl ViewTable {
    pub fn new(view: View) -> Self {
        let data_type = match view.data_type {
            ViewDataType::RichText => SqlViewDataType::RichText,
            ViewDataType::PlainText => SqlViewDataType::PlainText,
            ViewDataType::Grid => SqlViewDataType::Grid,
        };

        ViewTable {
            id: view.id,
            belong_to_id: view.belong_to_id,
            name: view.name,
            desc: view.desc,
            modified_time: view.modified_time,
            create_time: view.create_time,
            thumbnail: view.thumbnail,
            view_type: data_type,
            version: 0,
            is_trash: false,
        }
    }
}

impl std::convert::From<ViewTable> for View {
    fn from(table: ViewTable) -> Self {
        let data_type = match table.view_type {
            SqlViewDataType::RichText => ViewDataType::RichText,
            SqlViewDataType::PlainText => ViewDataType::PlainText,
            SqlViewDataType::Grid => ViewDataType::Grid,
        };

        View {
            id: table.id,
            belong_to_id: table.belong_to_id,
            name: table.name,
            desc: table.desc,
            data_type,
            belongings: RepeatedView::default(),
            modified_time: table.modified_time,
            version: table.version,
            create_time: table.create_time,
            ext_data: "".to_string(),
            thumbnail: table.thumbnail,
            // Store the view in ViewTable was deprecated since v0.0.2.
            // No need worry about plugin_type.
            plugin_type: 0,
        }
    }
}

impl std::convert::From<ViewTable> for Trash {
    fn from(table: ViewTable) -> Self {
        Trash {
            id: table.id,
            name: table.name,
            modified_time: table.modified_time,
            create_time: table.create_time,
            ty: TrashType::TrashView,
        }
    }
}

#[derive(AsChangeset, Identifiable, Clone, Default, Debug)]
#[table_name = "view_table"]
pub struct ViewChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
    pub thumbnail: Option<String>,
    pub modified_time: i64,
}

impl ViewChangeset {
    pub(crate) fn new(params: UpdateViewParams) -> Self {
        ViewChangeset {
            id: params.view_id,
            name: params.name,
            desc: params.desc,
            thumbnail: params.thumbnail,
            modified_time: timestamp(),
        }
    }

    pub(crate) fn from_table(table: ViewTable) -> Self {
        ViewChangeset {
            id: table.id,
            name: Some(table.name),
            desc: Some(table.desc),
            thumbnail: Some(table.thumbnail),
            modified_time: table.modified_time,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum SqlViewDataType {
    RichText = 0,
    PlainText = 1,
    Grid = 2,
}

impl std::default::Default for SqlViewDataType {
    fn default() -> Self {
        SqlViewDataType::RichText
    }
}

impl std::convert::From<i32> for SqlViewDataType {
    fn from(value: i32) -> Self {
        match value {
            0 => SqlViewDataType::RichText,
            1 => SqlViewDataType::PlainText,
            2 => SqlViewDataType::Grid,
            o => {
                log::error!("Unsupported view type {}, fallback to ViewType::Docs", o);
                SqlViewDataType::PlainText
            }
        }
    }
}

impl SqlViewDataType {
    pub fn value(&self) -> i32 {
        *self as i32
    }
}

impl_sql_integer_expression!(SqlViewDataType);
