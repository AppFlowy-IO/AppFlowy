use crate::util::sqlx_ext::SqlBuilder;
use backend_service::errors::{invalid_params, ServerError};
use chrono::{DateTime, NaiveDateTime, Utc};
use flowy_folder_data_model::{
    parser::view::ViewIdentify,
    protobuf::{RepeatedView as RepeatedViewPB, View as ViewPB, ViewType as ViewTypePB},
};
use protobuf::ProtobufEnum;
use sqlx::postgres::PgArguments;
use uuid::Uuid;

pub(crate) const VIEW_TABLE: &str = "view_table";

pub struct NewViewSqlBuilder {
    table: ViewTable,
}

impl NewViewSqlBuilder {
    pub fn new(view_id: Uuid, belong_to_id: &str) -> Self {
        let time = Utc::now();

        let table = ViewTable {
            id: view_id,
            belong_to_id: belong_to_id.to_string(),
            name: "".to_string(),
            description: "".to_string(),
            modified_time: time,
            create_time: time,
            thumbnail: "".to_string(),
            view_type: ViewTypePB::Doc.value(),
        };

        Self { table }
    }

    pub fn from_view(view: ViewPB) -> Result<Self, ServerError> {
        let view_id = ViewIdentify::parse(view.id).map_err(invalid_params)?;
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

    pub fn view_type(mut self, view_type: ViewTypePB) -> Self {
        self.table.view_type = view_type.value();
        self
    }

    pub fn build(self) -> Result<(String, PgArguments, ViewPB), ServerError> {
        let view: ViewPB = self.table.clone().into();

        let (sql, args) = SqlBuilder::create(VIEW_TABLE)
            .add_field_with_arg("id", self.table.id)
            .add_field_with_arg("belong_to_id", self.table.belong_to_id)
            .add_field_with_arg("name", self.table.name)
            .add_field_with_arg("description", self.table.description)
            .add_field_with_arg("modified_time", self.table.modified_time)
            .add_field_with_arg("create_time", self.table.create_time)
            .add_field_with_arg("thumbnail", self.table.thumbnail)
            .add_field_with_arg("view_type", self.table.view_type)
            .build()?;

        Ok((sql, args, view))
    }
}

pub(crate) fn check_view_ids(ids: Vec<String>) -> Result<Vec<Uuid>, ServerError> {
    let mut view_ids = vec![];
    for id in ids {
        view_ids.push(check_view_id(id)?);
    }
    Ok(view_ids)
}

pub(crate) fn check_view_id(id: String) -> Result<Uuid, ServerError> {
    let view_id = ViewIdentify::parse(id).map_err(invalid_params)?;
    let view_id = Uuid::parse_str(view_id.as_ref())?;
    Ok(view_id)
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct ViewTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) belong_to_id: String,
    pub(crate) name: String,
    pub(crate) description: String,
    pub(crate) modified_time: chrono::DateTime<Utc>,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) thumbnail: String,
    pub(crate) view_type: i32,
}
impl std::convert::From<ViewTable> for ViewPB {
    fn from(table: ViewTable) -> Self {
        let view_type = ViewTypePB::from_i32(table.view_type).unwrap_or(ViewTypePB::Doc);

        let mut view = ViewPB::default();
        view.set_id(table.id.to_string());
        view.set_belong_to_id(table.belong_to_id);
        view.set_name(table.name);
        view.set_desc(table.description);
        view.set_view_type(view_type);
        view.set_belongings(RepeatedViewPB::default());
        view.set_create_time(table.create_time.timestamp());
        view.set_modified_time(table.modified_time.timestamp());

        view
    }
}
