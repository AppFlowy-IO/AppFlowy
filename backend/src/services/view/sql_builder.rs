use crate::{
    entities::workspace::{ViewTable, VIEW_TABLE},
    sqlx_ext::SqlBuilder,
};
use backend_service::errors::{invalid_params, ServerError};
use chrono::{DateTime, NaiveDateTime, Utc};
use flowy_core_data_model::{
    parser::view::ViewId,
    protobuf::{View, ViewType},
};
use protobuf::ProtobufEnum;
use sqlx::postgres::PgArguments;
use uuid::Uuid;

pub struct NewViewSqlBuilder {
    table: ViewTable,
}

impl NewViewSqlBuilder {
    pub fn new(belong_to_id: &str) -> Self {
        let uuid = uuid::Uuid::new_v4();
        let time = Utc::now();

        let table = ViewTable {
            id: uuid,
            belong_to_id: belong_to_id.to_string(),
            name: "".to_string(),
            description: "".to_string(),
            modified_time: time,
            create_time: time,
            thumbnail: "".to_string(),
            view_type: ViewType::Doc.value(),
        };

        Self { table }
    }

    pub fn from_view(view: View) -> Result<Self, ServerError> {
        let view_id = ViewId::parse(view.id).map_err(invalid_params)?;
        let view_id = Uuid::parse_str(view_id.as_ref())?;
        let create_time = DateTime::<Utc>::from_utc(NaiveDateTime::from_timestamp(view.create_time, 0), Utc);
        let modified_time = DateTime::<Utc>::from_utc(NaiveDateTime::from_timestamp(view.modified_time, 0), Utc);

        let table = ViewTable {
            id: view_id,
            belong_to_id: view.belong_to_id,
            name: view.name,
            description: view.desc,
            modified_time,
            create_time,
            thumbnail: "".to_string(),
            view_type: view.view_type.value(),
        };
        Ok(Self { table })
    }

    pub fn name(mut self, name: &str) -> Self {
        self.table.name = name.to_string();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.table.description = desc.to_owned();
        self
    }

    pub fn thumbnail(mut self, thumbnail: &str) -> Self {
        self.table.thumbnail = thumbnail.to_owned();
        self
    }

    pub fn view_type(mut self, view_type: ViewType) -> Self {
        self.table.view_type = view_type.value();
        self
    }

    pub fn build(self) -> Result<(String, PgArguments, View), ServerError> {
        let view: View = self.table.clone().into();

        let (sql, args) = SqlBuilder::create(VIEW_TABLE)
            .add_arg("id", self.table.id)
            .add_arg("belong_to_id", self.table.belong_to_id)
            .add_arg("name", self.table.name)
            .add_arg("description", self.table.description)
            .add_arg("modified_time", self.table.modified_time)
            .add_arg("create_time", self.table.create_time)
            .add_arg("thumbnail", self.table.thumbnail)
            .add_arg("view_type", self.table.view_type)
            .build()?;

        Ok((sql, args, view))
    }
}

pub(crate) fn check_view_ids(ids: Vec<String>) -> Result<Vec<Uuid>, ServerError> {
    let mut view_ids = vec![];
    for id in ids {
        let view_id = ViewId::parse(id).map_err(invalid_params)?;
        let view_id = Uuid::parse_str(view_id.as_ref())?;
        view_ids.push(view_id);
    }
    Ok(view_ids)
}
