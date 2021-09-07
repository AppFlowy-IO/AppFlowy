use crate::{
    entities::view::{CreateViewParams, UpdateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    observable::WorkspaceObservable,
    services::{helper::spawn, server::Server},
    sql_tables::view::{ViewTable, ViewTableChangeset, ViewTableSql},
};

use crate::{
    entities::view::{DeleteViewParams, QueryViewParams, RepeatedView},
    module::WorkspaceUser,
    observable::ObservableBuilder,
};
use std::sync::Arc;

pub(crate) struct ViewController {
    user: Arc<dyn WorkspaceUser>,
    sql: Arc<ViewTableSql>,
    server: Server,
}

impl ViewController {
    pub(crate) fn new(user: Arc<dyn WorkspaceUser>, database: Arc<dyn WorkspaceDatabase>, server: Server) -> Self {
        let sql = Arc::new(ViewTableSql { database });
        Self { user, sql, server }
    }

    pub(crate) async fn create_view(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let view = self.create_view_on_server(params).await?;
        let view_table = ViewTable::new(view.clone());
        let _ = self.sql.create_view(view_table)?;

        let repeated_view = self.read_local_views_belong_to(&view.belong_to_id)?;
        ObservableBuilder::new(&view.belong_to_id, WorkspaceObservable::AppCreateView)
            .payload(repeated_view)
            .build();
        Ok(view)
    }

    pub(crate) async fn read_view(&self, params: QueryViewParams) -> Result<View, WorkspaceError> {
        let view_table = self.sql.read_view(&params.view_id, params.is_trash)?;
        let view: View = view_table.into();
        let _ = self.read_view_on_server(params).await?;
        Ok(view)
    }

    pub(crate) async fn delete_view(&self, view_id: &str) -> Result<(), WorkspaceError> {
        let view_table = self.sql.delete_view(view_id)?;
        let _ = self.delete_view_on_server(view_id).await?;

        let repeated_view = self.read_local_views_belong_to(&view_table.belong_to_id)?;
        ObservableBuilder::new(&view_table.belong_to_id, WorkspaceObservable::AppDeleteView)
            .payload(repeated_view)
            .build();
        Ok(())
    }

    // belong_to_id will be the app_id or view_id.
    pub(crate) async fn read_views_belong_to(&self, belong_to_id: &str) -> Result<RepeatedView, WorkspaceError> {
        // TODO: read from server
        let views = self
            .sql
            .read_views_belong_to(belong_to_id)?
            .into_iter()
            .map(|view_table| view_table.into())
            .collect::<Vec<View>>();

        Ok(RepeatedView { items: views })
    }

    pub(crate) async fn update_view(&self, params: UpdateViewParams) -> Result<(), WorkspaceError> {
        let changeset = ViewTableChangeset::new(params.clone());
        let view_id = changeset.id.clone();
        let _ = self.sql.update_view(changeset)?;
        let _ = self.update_view_on_server(params).await?;

        let view: View = self.sql.read_view(&view_id, false)?.into();
        ObservableBuilder::new(&view_id, WorkspaceObservable::ViewUpdated)
            .payload(view)
            .build();
        Ok(())
    }
}

impl ViewController {
    #[tracing::instrument(skip(self), err)]
    async fn create_view_on_server(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let token = self.user.token()?;
        let view = self.server.create_view(&token, params).await?;
        Ok(view)
    }

    #[tracing::instrument(skip(self), err)]
    async fn update_view_on_server(&self, params: UpdateViewParams) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        spawn(async move {
            match server.update_view(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update view failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(skip(self), err)]
    async fn delete_view_on_server(&self, view_id: &str) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let params = DeleteViewParams {
            view_id: view_id.to_string(),
        };
        spawn(async move {
            match server.delete_view(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Delete view failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(skip(self), err)]
    async fn read_view_on_server(&self, params: QueryViewParams) -> Result<(), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        spawn(async move {
            match server.read_view(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Read view failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    // belong_to_id will be the app_id or view_id.
    fn read_local_views_belong_to(&self, belong_to_id: &str) -> Result<RepeatedView, WorkspaceError> {
        let views = self
            .sql
            .read_views_belong_to(belong_to_id)?
            .into_iter()
            .map(|view_table| view_table.into())
            .collect::<Vec<View>>();

        Ok(RepeatedView { items: views })
    }
}
