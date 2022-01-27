use crate::util::sqlx_ext::SqlBuilder;
use backend_service::errors::{invalid_params, ServerError};
use chrono::{DateTime, NaiveDateTime, Utc};
use flowy_folder_data_model::{parser::workspace::WorkspaceIdentify, protobuf::Workspace as WorkspacePB};
use sqlx::postgres::PgArguments;
use uuid::Uuid;

pub struct NewWorkspaceBuilder {
    table: WorkspaceTable,
}

impl NewWorkspaceBuilder {
    pub fn new(user_id: &str) -> Self {
        let uuid = uuid::Uuid::new_v4();
        let time = Utc::now();

        let table = WorkspaceTable {
            id: uuid,
            name: "".to_string(),
            description: "".to_string(),
            modified_time: time,
            create_time: time,
            user_id: user_id.to_string(),
        };
        Self { table }
    }

    pub fn from_workspace(user_id: &str, workspace: WorkspacePB) -> Result<Self, ServerError> {
        let workspace_id = check_workspace_id(workspace.id)?;
        let create_time = DateTime::<Utc>::from_utc(NaiveDateTime::from_timestamp(workspace.create_time, 0), Utc);
        let modified_time = DateTime::<Utc>::from_utc(NaiveDateTime::from_timestamp(workspace.modified_time, 0), Utc);

        let table = WorkspaceTable {
            id: workspace_id,
            name: workspace.name,
            description: workspace.desc,
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

    pub fn desc(mut self, desc: &str) -> Self {
        self.table.description = desc.to_owned();
        self
    }

    pub fn build(self) -> Result<(String, PgArguments, WorkspacePB), ServerError> {
        let workspace: WorkspacePB = self.table.clone().into();
        // TODO: use macro to fetch each field from struct
        let (sql, args) = SqlBuilder::create(WORKSPACE_TABLE)
            .add_field_with_arg("id", self.table.id)
            .add_field_with_arg("name", self.table.name)
            .add_field_with_arg("description", self.table.description)
            .add_field_with_arg("modified_time", self.table.modified_time)
            .add_field_with_arg("create_time", self.table.create_time)
            .add_field_with_arg("user_id", self.table.user_id)
            .build()?;

        Ok((sql, args, workspace))
    }
}

pub(crate) fn check_workspace_id(id: String) -> Result<Uuid, ServerError> {
    let workspace_id = WorkspaceIdentify::parse(id).map_err(invalid_params)?;
    let workspace_id = Uuid::parse_str(workspace_id.as_ref())?;
    Ok(workspace_id)
}

pub(crate) const WORKSPACE_TABLE: &str = "workspace_table";

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct WorkspaceTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) name: String,
    pub(crate) description: String,
    pub(crate) modified_time: chrono::DateTime<Utc>,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) user_id: String,
}
impl std::convert::From<WorkspaceTable> for WorkspacePB {
    fn from(table: WorkspaceTable) -> Self {
        let mut workspace = WorkspacePB::default();
        workspace.set_id(table.id.to_string());
        workspace.set_name(table.name.clone());
        workspace.set_desc(table.description.clone());
        workspace.set_modified_time(table.modified_time.timestamp());
        workspace.set_create_time(table.create_time.timestamp());
        workspace
    }
}
