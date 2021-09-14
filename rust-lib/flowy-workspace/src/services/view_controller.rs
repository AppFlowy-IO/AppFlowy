use crate::{
    entities::view::{CreateViewParams, UpdateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    observable::notify,
    services::{helper::spawn, server::Server},
    sql_tables::view::{ViewTable, ViewTableChangeset, ViewTableSql},
};

use crate::{
    entities::view::{DeleteViewParams, QueryViewParams, RepeatedView},
    module::WorkspaceUser,
    observable::WorkspaceObservable,
};
use flowy_database::SqliteConnection;
use flowy_document::{
    entities::doc::{ApplyChangesetParams, CreateDocParams, Doc, QueryDocParams, SaveDocParams},
    module::FlowyDocument,
};
use std::sync::Arc;

pub(crate) struct ViewController {
    user: Arc<dyn WorkspaceUser>,
    sql: Arc<ViewTableSql>,
    server: Server,
    database: Arc<dyn WorkspaceDatabase>,
    document: Arc<FlowyDocument>,
}

impl ViewController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        server: Server,
        document: Arc<FlowyDocument>,
    ) -> Self {
        let sql = Arc::new(ViewTableSql {});
        Self {
            user,
            sql,
            server,
            database,
            document,
        }
    }

    pub(crate) async fn create_view(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let view = self.create_view_on_server(params.clone()).await?;
        let conn = &*self.database.db_connection()?;
        // TODO: rollback anything created before if failed?
        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.save_view(view.clone(), conn)?;
            self.document.create(CreateDocParams::new(&view.id, params.data), conn)?;

            let repeated_view = self.read_local_views_belong_to(&view.belong_to_id, conn)?;
            notify(&view.belong_to_id, WorkspaceObservable::AppCreateView)
                .payload(repeated_view)
                .send();
            Ok(())
        })?;

        Ok(view)
    }

    pub(crate) fn save_view(&self, view: View, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        let view_table = ViewTable::new(view);
        let _ = self.sql.create_view(view_table, conn)?;
        Ok(())
    }

    pub(crate) async fn read_view(&self, params: QueryViewParams) -> Result<View, WorkspaceError> {
        let conn = self.database.db_connection()?;
        let view_table = self.sql.read_view(&params.view_id, Some(params.is_trash), &*conn)?;
        let view: View = view_table.into();
        let _ = self.read_view_on_server(params);
        Ok(view)
    }

    pub(crate) async fn open_view(&self, params: QueryDocParams) -> Result<Doc, WorkspaceError> {
        let doc = self.document.open(params, self.database.db_pool()?).await?;
        Ok(doc)
    }

    pub(crate) async fn delete_view(&self, params: DeleteViewParams) -> Result<(), WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        let _ = self.delete_view_on_server(&params.view_id);

        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let view_table = self.sql.delete_view(&params.view_id, conn)?;
            let _ = self.document.delete(params.into(), conn)?;

            let repeated_view = self.read_local_views_belong_to(&view_table.belong_to_id, conn)?;
            notify(&view_table.belong_to_id, WorkspaceObservable::AppDeleteView)
                .payload(repeated_view)
                .send();
            Ok(())
        })?;

        Ok(())
    }

    // belong_to_id will be the app_id or view_id.
    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn read_views_belong_to(&self, belong_to_id: &str) -> Result<RepeatedView, WorkspaceError> {
        // TODO: read from server
        let conn = self.database.db_connection()?;
        let repeated_view = self.read_local_views_belong_to(belong_to_id, &*conn)?;
        Ok(repeated_view)
    }

    pub(crate) async fn update_view(&self, params: UpdateViewParams) -> Result<(), WorkspaceError> {
        let conn = &*self.database.db_connection()?;
        let changeset = ViewTableChangeset::new(params.clone());
        let view_id = changeset.id.clone();

        conn.immediate_transaction::<_, WorkspaceError, _>(|| {
            let _ = self.sql.update_view(changeset, conn)?;
            let view: View = self.sql.read_view(&view_id, None, conn)?.into();
            notify(&view_id, WorkspaceObservable::ViewUpdated).payload(view).send();
            Ok(())
        })?;

        let _ = self.update_view_on_server(params);
        Ok(())
    }

    pub(crate) async fn update_view_data(&self, params: SaveDocParams) -> Result<(), WorkspaceError> {
        let _ = self.document.update(params, self.database.db_pool()?).await?;
        Ok(())
    }

    pub(crate) async fn apply_changeset(&self, params: ApplyChangesetParams) -> Result<(), WorkspaceError> {
        let _ = self.document.apply_changeset(params).await?;
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
    fn update_view_on_server(&self, params: UpdateViewParams) -> Result<(), WorkspaceError> {
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
    fn delete_view_on_server(&self, view_id: &str) -> Result<(), WorkspaceError> {
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
    fn read_view_on_server(&self, params: QueryViewParams) -> Result<(), WorkspaceError> {
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
    fn read_local_views_belong_to(&self, belong_to_id: &str, conn: &SqliteConnection) -> Result<RepeatedView, WorkspaceError> {
        let views = self
            .sql
            .read_views_belong_to(belong_to_id, conn)?
            .into_iter()
            .map(|view_table| view_table.into())
            .collect::<Vec<View>>();

        Ok(RepeatedView { items: views })
    }
}
