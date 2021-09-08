use crate::{
    entities::{
        app::{App, RepeatedApp},
        workspace::*,
    },
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::{observable, WorkspaceObservable},
    services::{helper::spawn, server::Server, AppController},
    sql_tables::{
        app::{AppTable, AppTableSql},
        view::{ViewTable, ViewTableSql},
        workspace::{WorkspaceTable, WorkspaceTableChangeset, WorkspaceTableSql},
    },
};
use flowy_database::SqliteConnection;
use flowy_infra::kv::KV;
use std::sync::Arc;

pub(crate) struct WorkspaceController {
    pub user: Arc<dyn WorkspaceUser>,
    pub workspace_sql: Arc<WorkspaceTableSql>,
    pub app_sql: Arc<AppTableSql>,
    pub view_sql: Arc<ViewTableSql>,
    pub database: Arc<dyn WorkspaceDatabase>,
    pub app_controller: Arc<AppController>,
    server: Server,
}

impl WorkspaceController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        app_controller: Arc<AppController>,
        server: Server,
    ) -> Self {
        let workspace_sql = Arc::new(WorkspaceTableSql {});
        let app_sql = Arc::new(AppTableSql {});
        let view_sql = Arc::new(ViewTableSql {});
        Self {
            user,
            workspace_sql,
            app_sql,
            view_sql,
            database,
            app_controller,
            server,
        }
    }

    pub(crate) async fn create_workspace(&self, params: CreateWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let workspace = self.create_workspace_on_server(params.clone()).await?;
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let workspace_table = WorkspaceTable::new(workspace.clone(), &user_id);
        let conn = &*self.database.db_connection()?;
        //[[immediate_transaction]]
        // https://sqlite.org/lang_transaction.html
        // IMMEDIATE cause the database connection to start a new write immediately,
        // without waiting for a write statement. The BEGIN IMMEDIATE might fail
        // with SQLITE_BUSY if another write transaction is already active on another
        // database connection.
        //
        // EXCLUSIVE is similar to IMMEDIATE in that a write transaction is started
        // immediately. EXCLUSIVE and IMMEDIATE are the same in WAL mode, but in
        // other journaling modes, EXCLUSIVE prevents other database connections from
        // reading the database while the transaction is underway.
        (conn).immediate_transaction::<_, WorkspaceError, _>(|| {
            self.workspace_sql.create_workspace(workspace_table, conn)?;
            let repeated_workspace = self.read_local_workspaces(None, &user_id, conn)?;
            observable(&token, WorkspaceObservable::UserCreateWorkspace)
                .payload(repeated_workspace)
                .build();

            Ok(())
        })?;

        Ok(workspace)
    }

    pub(crate) async fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let _ = self.update_workspace_on_server(params.clone()).await?;

        let changeset = WorkspaceTableChangeset::new(params);
        let workspace_id = changeset.id.clone();
        let conn = &*self.database.db_connection()?;
        (conn).immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.workspace_sql.update_workspace(changeset, conn)?;
            let user_id = self.user.user_id()?;
            let workspace = self.read_local_workspace(workspace_id.clone(), &user_id, conn)?;
            observable(&workspace_id, WorkspaceObservable::WorkspaceUpdated)
                .payload(workspace)
                .build();

            Ok(())
        })?;

        Ok(())
    }

    pub(crate) async fn delete_workspace(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let _ = self.delete_workspace_on_server(workspace_id).await?;
        let conn = &*self.database.db_connection()?;
        (conn).immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.workspace_sql.delete_workspace(workspace_id, conn)?;
            let repeated_workspace = self.read_local_workspaces(None, &user_id, conn)?;
            observable(&token, WorkspaceObservable::UserDeleteWorkspace)
                .payload(repeated_workspace)
                .build();

            Ok(())
        })?;

        Ok(())
    }

    pub(crate) async fn open_workspace(&self, params: QueryWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        let conn = self.database.db_connection()?;
        if let Some(workspace_id) = params.workspace_id.clone() {
            let workspace = self.read_local_workspace(workspace_id, &user_id, &*conn)?;
            set_current_workspace(&workspace.id);
            Ok(workspace)
        } else {
            return Err(ErrorBuilder::new(ErrorCode::WorkspaceIdInvalid)
                .msg("Opened workspace id should not be empty")
                .build());
        }
    }

    pub(crate) async fn read_workspaces(&self, params: QueryWorkspaceParams) -> Result<RepeatedWorkspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        let _ = self.read_workspaces_on_server(user_id.clone(), params.clone()).await;

        let conn = self.database.db_connection()?;
        let workspaces = self.read_local_workspaces(params.workspace_id.clone(), &user_id, &*conn)?;
        Ok(workspaces)
    }

    pub(crate) async fn read_cur_workspace(&self) -> Result<Workspace, WorkspaceError> {
        let workspace_id = get_current_workspace()?;
        let user_id = self.user.user_id()?;
        let params = QueryWorkspaceParams {
            workspace_id: Some(workspace_id.clone()),
        };
        let _ = self.read_workspaces_on_server(user_id.clone(), params).await?;

        let conn = self.database.db_connection()?;
        let workspace = self.read_local_workspace(workspace_id, &user_id, &*conn)?;
        Ok(workspace)
    }

    pub(crate) async fn read_workspace_apps(&self) -> Result<RepeatedApp, WorkspaceError> {
        let workspace_id = get_current_workspace()?;
        let conn = self.database.db_connection()?;
        let apps = self.read_local_apps(&workspace_id, &*conn)?;
        // TODO: read from server
        Ok(RepeatedApp { items: apps })
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    fn read_local_workspaces(
        &self,
        workspace_id: Option<String>,
        user_id: &str,
        conn: &SqliteConnection,
    ) -> Result<RepeatedWorkspace, WorkspaceError> {
        let workspace_id = workspace_id.to_owned();
        let workspace_tables = self.workspace_sql.read_workspaces(workspace_id, user_id, conn)?;

        let mut workspaces = vec![];
        for table in workspace_tables {
            let apps = self.read_local_apps(&table.id, conn)?;
            let mut workspace: Workspace = table.into();
            workspace.apps.items = apps;
            workspaces.push(workspace);
        }
        Ok(RepeatedWorkspace { items: workspaces })
    }

    fn read_local_workspace(&self, workspace_id: String, user_id: &str, conn: &SqliteConnection) -> Result<Workspace, WorkspaceError> {
        // Opti: fetch single workspace from local db
        let mut repeated_workspace = self.read_local_workspaces(Some(workspace_id), user_id, conn)?;
        if repeated_workspace.is_empty() {
            return Err(ErrorBuilder::new(ErrorCode::RecordNotFound).build());
        }

        debug_assert_eq!(repeated_workspace.len(), 1);
        let workspace = repeated_workspace.drain(..1).collect::<Vec<Workspace>>().pop().unwrap();
        Ok(workspace)
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    fn read_local_apps(&self, workspace_id: &str, conn: &SqliteConnection) -> Result<Vec<App>, WorkspaceError> {
        let apps = self
            .workspace_sql
            .read_apps_belong_to_workspace(workspace_id, conn)?
            .into_iter()
            .map(|app_table| app_table.into())
            .collect::<Vec<App>>();

        Ok(apps)
    }
}

impl WorkspaceController {
    fn token_with_server(&self) -> Result<(String, Server), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        Ok((token, server))
    }

    #[tracing::instrument(skip(self), err)]
    async fn create_workspace_on_server(&self, params: CreateWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let token = self.user.token()?;
        let workspace = self.server.create_workspace(&token, params).await?;
        Ok(workspace)
    }

    #[tracing::instrument(skip(self), err)]
    async fn update_workspace_on_server(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let (token, server) = self.token_with_server()?;
        spawn(async move {
            match server.update_workspace(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update workspace failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(skip(self), err)]
    async fn delete_workspace_on_server(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let params = DeleteWorkspaceParams {
            workspace_id: workspace_id.to_string(),
        };
        let (token, server) = self.token_with_server()?;
        spawn(async move {
            match server.delete_workspace(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Delete workspace failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(skip(self), err)]
    async fn read_workspaces_on_server(&self, user_id: String, params: QueryWorkspaceParams) -> Result<(), WorkspaceError> {
        let (token, server) = self.token_with_server()?;
        let workspace_sql = self.workspace_sql.clone();
        let app_sql = self.app_sql.clone();
        let view_sql = self.view_sql.clone();
        let conn = self.database.db_connection()?;
        spawn(async move {
            // Opti: retry?
            let workspaces = server.read_workspace(&token, params).await?;
            let _ = (&*conn).immediate_transaction::<_, WorkspaceError, _>(|| {
                log::debug!("Save {} workspace", workspaces.len());
                for workspace in &workspaces.items {
                    let mut m_workspace = workspace.clone();
                    let apps = m_workspace.apps.take_items();
                    let workspace_table = WorkspaceTable::new(m_workspace, &user_id);

                    let _ = workspace_sql.create_workspace(workspace_table, &*conn)?;
                    log::debug!("Save {} apps", apps.len());
                    for mut app in apps {
                        let views = app.belongings.take_items();
                        match app_sql.create_app(AppTable::new(app), &*conn) {
                            Ok(_) => {},
                            Err(e) => log::error!("create app failed: {:?}", e),
                        }

                        log::debug!("Save {} views", views.len());
                        for view in views {
                            match view_sql.create_view(ViewTable::new(view), &*conn) {
                                Ok(_) => {},
                                Err(e) => log::error!("create view failed: {:?}", e),
                            }
                        }
                    }
                }
                Ok(())
            })?;

            observable(&token, WorkspaceObservable::WorkspaceListUpdated)
                .payload(workspaces)
                .build();
            Result::<(), WorkspaceError>::Ok(())
        });

        Ok(())
    }
}

const CURRENT_WORKSPACE_ID: &str = "current_workspace_id";

fn set_current_workspace(workspace: &str) { KV::set_str(CURRENT_WORKSPACE_ID, workspace.to_owned()); }

fn get_current_workspace() -> Result<String, WorkspaceError> {
    match KV::get_str(CURRENT_WORKSPACE_ID) {
        None => Err(ErrorBuilder::new(ErrorCode::CurrentWorkspaceNotFound).build()),
        Some(workspace_id) => Ok(workspace_id),
    }
}
