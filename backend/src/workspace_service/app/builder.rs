use crate::{entities::workspace::AppTable, sqlx_ext::SqlBuilder};
use chrono::Utc;
use flowy_net::errors::{invalid_params, ServerError};
use flowy_workspace::{
    entities::app::parser::AppId,
    protobuf::{App, ColorStyle, RepeatedView},
};
use protobuf::Message;
use sqlx::postgres::PgArguments;
use uuid::Uuid;

pub struct Builder {
    table: AppTable,
}

impl Builder {
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
            is_trash: false,
        };

        Self { table }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.table.name = name.to_string();
        self
    }

    pub fn last_view_id(mut self, view_id: &str) -> Self {
        self.table.last_view_id = view_id.to_string();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.table.description = desc.to_owned();
        self
    }

    pub fn color_style(mut self, color_style: ColorStyle) -> Self {
        self.table.color_style = color_style
            .write_to_bytes()
            .unwrap_or(default_color_style());
        self
    }

    pub fn build(self) -> Result<(String, PgArguments, App), ServerError> {
        let app = make_app_from_table(self.table.clone(), RepeatedView::default());

        let (sql, args) = SqlBuilder::create("app_table")
            .add_arg("id", self.table.id)
            .add_arg("workspace_id", self.table.workspace_id)
            .add_arg("name", self.table.name)
            .add_arg("description", self.table.description)
            .add_arg("color_style", self.table.color_style)
            .add_arg("modified_time", self.table.modified_time)
            .add_arg("create_time", self.table.create_time)
            .add_arg("user_id", self.table.user_id)
            .build()?;

        Ok((sql, args, app))
    }
}

fn default_color_style() -> Vec<u8> {
    let mut style = ColorStyle::default();
    match style.write_to_bytes() {
        Ok(bytes) => bytes,
        Err(e) => {
            log::error!("Serialize color style failed: {:?}", e);
            vec![]
        },
    }
}

pub(crate) fn make_app_from_table(table: AppTable, views: RepeatedView) -> App {
    let mut app = App::default();
    app.set_id(table.id.to_string());
    app.set_workspace_id(table.workspace_id.to_string());
    app.set_name(table.name.clone());
    app.set_desc(table.description.clone());
    app.set_belongings(views);

    app
}

pub(crate) fn check_app_id(id: String) -> Result<Uuid, ServerError> {
    let app_id = AppId::parse(id).map_err(invalid_params)?;
    let app_id = Uuid::parse_str(app_id.as_ref())?;
    Ok(app_id)
}
