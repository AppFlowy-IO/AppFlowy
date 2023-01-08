use crate::{entities::workspace::UpdateWorkspaceParams, errors::FlowyError};
use diesel::SqliteConnection;
use flowy_database::{
    prelude::*,
    schema::{workspace_table, workspace_table::dsl},
};
use folder_rev_model::WorkspaceRevision;

pub(crate) struct WorkspaceTableSql();
impl WorkspaceTableSql {
    pub(crate) fn create_workspace(
        user_id: &str,
        workspace_rev: WorkspaceRevision,
        conn: &SqliteConnection,
    ) -> Result<(), FlowyError> {
        let table = WorkspaceTable::new(workspace_rev, user_id);
        match diesel_record_count!(workspace_table, &table.id, conn) {
            0 => diesel_insert_table!(workspace_table, table.clone(), conn),
            _ => {
                let changeset = WorkspaceChangeset::from_table(table);
                diesel_update_table!(workspace_table, changeset, conn);
            }
        }
        Ok(())
    }

    pub(crate) fn read_workspaces(
        user_id: &str,
        workspace_id: Option<String>,
        conn: &SqliteConnection,
    ) -> Result<Vec<WorkspaceTable>, FlowyError> {
        let mut filter = dsl::workspace_table
            .filter(workspace_table::user_id.eq(user_id))
            .order(workspace_table::create_time.asc())
            .into_boxed();

        if let Some(workspace_id) = workspace_id {
            filter = filter.filter(workspace_table::id.eq(workspace_id));
        };

        let workspaces = filter.load::<WorkspaceTable>(conn)?;

        Ok(workspaces)
    }

    #[allow(dead_code)]
    pub(crate) fn update_workspace(changeset: WorkspaceChangeset, conn: &SqliteConnection) -> Result<(), FlowyError> {
        diesel_update_table!(workspace_table, changeset, conn);
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) fn delete_workspace(workspace_id: &str, conn: &SqliteConnection) -> Result<(), FlowyError> {
        diesel_delete_table!(workspace_table, workspace_id, conn);
        Ok(())
    }
}

#[derive(PartialEq, Eq, Clone, Debug, Queryable, Identifiable, Insertable)]
#[table_name = "workspace_table"]
pub struct WorkspaceTable {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub user_id: String,
    pub version: i64,
}

impl WorkspaceTable {
    #[allow(dead_code)]
    pub fn new(workspace_rev: WorkspaceRevision, user_id: &str) -> Self {
        WorkspaceTable {
            id: workspace_rev.id,
            name: workspace_rev.name,
            desc: workspace_rev.desc,
            modified_time: workspace_rev.modified_time,
            create_time: workspace_rev.create_time,
            user_id: user_id.to_owned(),
            version: 0,
        }
    }
}

impl std::convert::From<WorkspaceTable> for WorkspaceRevision {
    fn from(table: WorkspaceTable) -> Self {
        WorkspaceRevision {
            id: table.id,
            name: table.name,
            desc: table.desc,
            apps: vec![],
            modified_time: table.modified_time,
            create_time: table.create_time,
        }
    }
}

#[derive(AsChangeset, Identifiable, Clone, Default, Debug)]
#[table_name = "workspace_table"]
pub struct WorkspaceChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
}

impl WorkspaceChangeset {
    pub fn new(params: UpdateWorkspaceParams) -> Self {
        WorkspaceChangeset {
            id: params.id,
            name: params.name,
            desc: params.desc,
        }
    }

    pub(crate) fn from_table(table: WorkspaceTable) -> Self {
        WorkspaceChangeset {
            id: table.id,
            name: Some(table.name),
            desc: Some(table.desc),
        }
    }
}
