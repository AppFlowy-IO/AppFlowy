use crate::{
    entities::workspace::{WorkspaceTable, WORKSPACE_TABLE},
    sqlx_ext::SqlBuilder,
};
use chrono::Utc;
use flowy_net::errors::{invalid_params, ServerError};
use flowy_workspace_infra::{
    parser::workspace::WorkspaceId,
    protobuf::{RepeatedApp, Workspace},
};
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

    pub fn name(mut self, name: &str) -> Self {
        self.table.name = name.to_string();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.table.description = desc.to_owned();
        self
    }

    pub fn build(self) -> Result<(String, PgArguments, Workspace), ServerError> {
        let workspace = make_workspace_from_table(self.table.clone(), None);

        // TODO: use macro to fetch each field from struct
        let (sql, args) = SqlBuilder::create(WORKSPACE_TABLE)
            .add_arg("id", self.table.id)
            .add_arg("name", self.table.name)
            .add_arg("description", self.table.description)
            .add_arg("modified_time", self.table.modified_time)
            .add_arg("create_time", self.table.create_time)
            .add_arg("user_id", self.table.user_id)
            .build()?;

        Ok((sql, args, workspace))
    }
}

pub(crate) fn make_workspace_from_table(table: WorkspaceTable, apps: Option<RepeatedApp>) -> Workspace {
    let mut workspace = Workspace {
        id: table.id.to_string(),
        name: table.name,
        desc: table.description,
        apps: Default::default(),
        modified_time: table.modified_time.timestamp(),
        create_time: table.create_time.timestamp(),
        unknown_fields: Default::default(),
        cached_size: Default::default(),
    };

    if let Some(apps) = apps {
        workspace.set_apps(apps);
    }

    workspace
}

pub(crate) fn check_workspace_id(id: String) -> Result<Uuid, ServerError> {
    let workspace_id = WorkspaceId::parse(id).map_err(invalid_params)?;
    let workspace_id = Uuid::parse_str(workspace_id.as_ref())?;
    Ok(workspace_id)
}
