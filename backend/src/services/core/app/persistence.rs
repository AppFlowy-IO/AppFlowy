use crate::util::sqlx_ext::SqlBuilder;
use backend_service::errors::{invalid_params, ServerError};
use chrono::{DateTime, NaiveDateTime, Utc};
use flowy_core_data_model::{
    parser::app::AppIdentify,
<<<<<<< HEAD
    protobuf::{App, ColorStyle, RepeatedView},
=======
    protobuf::{App as AppPB, ColorStyle as ColorStylePB, RepeatedView as RepeatedViewPB},
>>>>>>> upstream/main
};
use protobuf::Message;
use sqlx::postgres::PgArguments;
use uuid::Uuid;

pub(crate) const APP_TABLE: &str = "app_table";

pub struct NewAppSqlBuilder {
    table: AppTable,
}

impl NewAppSqlBuilder {
    pub fn new(user_id: &str, workspace_id: &str) -> Self {
        let uuid = uuid::Uuid::new_v4();
        let time = Utc::now();

        let table = AppTable {
            id: uuid,
            workspace_id: workspace_id.to_string(),
            name: "".to_string(),
            description: "".to_string(),
            color_style: default_color_style(),
            last_view_id: "".to_string(),
            modified_time: time,
            create_time: time,
            user_id: user_id.to_string(),
        };

        Self { table }
    }

    pub fn from_app(user_id: &str, app: AppPB) -> Result<Self, ServerError> {
        let app_id = check_app_id(app.id)?;
        let create_time = DateTime::<Utc>::from_utc(NaiveDateTime::from_timestamp(app.create_time, 0), Utc);
        let modified_time = DateTime::<Utc>::from_utc(NaiveDateTime::from_timestamp(app.modified_time, 0), Utc);

        let table = AppTable {
            id: app_id,
            workspace_id: app.workspace_id,
            name: app.name,
            description: app.desc,
            color_style: default_color_style(),
            last_view_id: "".to_string(),
            modified_time,
            create_time,
            user_id: user_id.to_string(),
        };

        Ok(Self { table })
    }

    pub fn name(mut self, name: &str) -> Self {
        self.table.name = name.to_string();
        self
    }

    #[allow(dead_code)]
    pub fn last_view_id(mut self, view_id: &str) -> Self {
        self.table.last_view_id = view_id.to_string();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.table.description = desc.to_owned();
        self
    }

    pub fn color_style(mut self, color_style: ColorStylePB) -> Self {
        self.table.color_style = color_style.write_to_bytes().unwrap_or_else(|_| default_color_style());
        self
    }

    pub fn build(self) -> Result<(String, PgArguments, AppPB), ServerError> {
        let app: AppPB = self.table.clone().into();

        let (sql, args) = SqlBuilder::create(APP_TABLE)
            .add_field_with_arg("id", self.table.id)
            .add_field_with_arg("workspace_id", self.table.workspace_id)
            .add_field_with_arg("name", self.table.name)
            .add_field_with_arg("description", self.table.description)
            .add_field_with_arg("color_style", self.table.color_style)
            .add_field_with_arg("modified_time", self.table.modified_time)
            .add_field_with_arg("create_time", self.table.create_time)
            .add_field_with_arg("user_id", self.table.user_id)
            .build()?;

        Ok((sql, args, app))
    }
}

fn default_color_style() -> Vec<u8> {
    let style = ColorStylePB::default();
    match style.write_to_bytes() {
        Ok(bytes) => bytes,
        Err(e) => {
            log::error!("Serialize color style failed: {:?}", e);
            vec![]
        },
    }
}

pub(crate) fn check_app_id(id: String) -> Result<Uuid, ServerError> {
    let app_id = AppIdentify::parse(id).map_err(invalid_params)?;
    let app_id = Uuid::parse_str(app_id.as_ref())?;
    Ok(app_id)
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct AppTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) workspace_id: String,
    pub(crate) name: String,
    pub(crate) description: String,
    pub(crate) color_style: Vec<u8>,
    pub(crate) last_view_id: String,
    pub(crate) modified_time: chrono::DateTime<Utc>,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) user_id: String,
}
impl std::convert::From<AppTable> for AppPB {
    fn from(table: AppTable) -> Self {
        let mut app = AppPB::default();
        app.set_id(table.id.to_string());
        app.set_workspace_id(table.workspace_id.to_string());
        app.set_name(table.name.clone());
        app.set_desc(table.description.clone());
        app.set_belongings(RepeatedViewPB::default());
        app.set_modified_time(table.modified_time.timestamp());
        app.set_create_time(table.create_time.timestamp());

        app
    }
}
