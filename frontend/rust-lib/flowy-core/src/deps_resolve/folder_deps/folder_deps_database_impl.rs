use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use bytes::Bytes;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use collab_folder::{View, ViewLayout};
use collab_plugins::local_storage::kv::KVTransactionDB;
use flowy_database2::DatabaseManager;
use flowy_database2::entities::DatabaseLayoutPB;
use flowy_database2::services::share::csv::CSVFormat;
use flowy_database2::template::{make_default_board, make_default_calendar, make_default_grid};
use flowy_error::FlowyError;
use flowy_folder::entities::{CreateViewParams, ViewLayoutPB};
use flowy_folder::manager::FolderUser;
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{DatabaseEncodedCollab, FolderOperationHandler, GatherEncodedCollab, ImportedData, ViewData};
use flowy_user::services::data_import::{load_collab_by_object_id, load_collab_by_object_ids};
use lib_infra::async_trait::async_trait;

pub struct DatabaseFolderOperation(pub Arc<DatabaseManager>);

#[async_trait]
impl FolderOperationHandler for DatabaseFolderOperation {
    async fn open_view(&self, view_id: &str) -> Result<(), FlowyError> {
        self.0.open_database_view(view_id).await?;
        Ok(())
    }

    async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
        self.0.close_database_view(view_id).await?;
        Ok(())
    }

    async fn delete_view(&self, view_id: &str) -> Result<(), FlowyError> {
        match self.0.delete_database_view(view_id).await {
            Ok(_) => tracing::trace!("Delete database view: {}", view_id),
            Err(e) => tracing::error!("🔴delete database failed: {}", e),
        }
        Ok(())
    }

    async fn gather_publish_encode_collab(
        &self,
        user: &Arc<dyn FolderUser>,
        view_id: &str,
    ) -> Result<GatherEncodedCollab, FlowyError> {
        let workspace_id = user.workspace_id()?;
        // get the collab_object_id for the database.
        //
        // the collab object_id for the database is not the view_id,
        //  we should use the view_id to get the database_id
        let oid = self.0.get_database_id_with_view_id(view_id).await?;
        let row_oids = self.0.get_database_row_ids_with_view_id(view_id).await?;
        let row_metas = self
            .0
            .get_database_row_metas_with_view_id(view_id, row_oids.clone())
            .await?;
        let row_document_ids = row_metas
            .iter()
            .filter_map(|meta| meta.document_id.clone())
            .collect::<Vec<_>>();
        let row_oids = row_oids
            .into_iter()
            .map(|oid| oid.into_inner())
            .collect::<Vec<_>>();
        let database_metas = self.0.get_all_databases_meta().await;

        let uid = user
            .user_id()
            .map_err(|e| e.with_context("unable to get the uid: {}"))?;

        // get the collab db
        let collab_db = user
            .collab_db(uid)
            .map_err(|e| e.with_context("unable to get the collab"))?;
        let collab_db = collab_db.upgrade().ok_or_else(|| {
            FlowyError::internal().with_context(
                "The collab db has been dropped, indicating that the user has switched to a new account",
            )
        })?;

        tokio::task::spawn_blocking(move || {
            let collab_read_txn = collab_db.read_txn();
            let database_collab = load_collab_by_object_id(uid, &collab_read_txn, &workspace_id, &oid)
                .map_err(|e| {
                    FlowyError::internal().with_context(format!("load database collab failed: {}", e))
                })?;

            let database_encoded_collab = database_collab
                // encode the collab and check the integrity of the collab
                .encode_collab_v1(|collab| CollabType::Database.validate_require_data(collab))
                .map_err(|e| {
                    FlowyError::internal().with_context(format!("encode database collab failed: {}", e))
                })?;

            let database_row_encoded_collabs =
                load_collab_by_object_ids(uid, &workspace_id, &collab_read_txn, &row_oids)
                    .0
                    .into_iter()
                    .map(|(oid, collab)| {
                        collab
                            .encode_collab_v1(|c| CollabType::DatabaseRow.validate_require_data(c))
                            .map(|encoded| (oid, encoded))
                            .map_err(|e| {
                                FlowyError::internal().with_context(format!("Database row collab error: {}", e))
                            })
                    })
                    .collect::<Result<HashMap<_, _>, FlowyError>>()?;

            let database_relations = database_metas
                .into_iter()
                .filter_map(|meta| {
                    meta
                        .linked_views
                        .clone()
                        .into_iter()
                        .next()
                        .map(|lv| (meta.database_id, lv))
                })
                .collect::<HashMap<_, _>>();

            let database_row_document_encoded_collabs =
                load_collab_by_object_ids(uid, &workspace_id, &collab_read_txn, &row_document_ids)
                    .0
                    .into_iter()
                    .map(|(oid, collab)| {
                        collab
                            .encode_collab_v1(|c| CollabType::Document.validate_require_data(c))
                            .map(|encoded| (oid, encoded))
                            .map_err(|e| {
                                FlowyError::internal()
                                    .with_context(format!("Database row document collab error: {}", e))
                            })
                    })
                    .collect::<Result<HashMap<_, _>, FlowyError>>()?;

            Ok(GatherEncodedCollab::Database(DatabaseEncodedCollab {
                database_encoded_collab,
                database_row_encoded_collabs,
                database_row_document_encoded_collabs,
                database_relations,
            }))
        })
            .await?
    }

    async fn duplicate_view(&self, view_id: &str) -> Result<Bytes, FlowyError> {
        Ok(Bytes::from(view_id.to_string()))
    }

    /// Create a database view with duplicated data.
    /// If the ext contains the {"database_id": "xx"}, then it will link
    /// to the existing database.
    async fn create_view_with_view_data(
        &self,
        _user_id: i64,
        params: CreateViewParams,
    ) -> Result<Option<EncodedCollab>, FlowyError> {
        match CreateDatabaseExtParams::from_map(params.meta.clone()) {
            None => match params.initial_data {
                ViewData::DuplicateData(data) => {
                    let duplicated_view_id =
                        String::from_utf8(data.to_vec()).map_err(|_| FlowyError::invalid_data())?;
                    let encoded_collab = self
                        .0
                        .duplicate_database(&duplicated_view_id, &params.view_id)
                        .await?;
                    Ok(Some(encoded_collab))
                },
                ViewData::Data(data) => {
                    let encoded_collab = self
                        .0
                        .create_database_with_data(&params.view_id, data.to_vec())
                        .await?;
                    Ok(Some(encoded_collab))
                },
                ViewData::Empty => Ok(None),
            },
            Some(database_params) => {
                let layout = match params.layout {
                    ViewLayoutPB::Board => DatabaseLayoutPB::Board,
                    ViewLayoutPB::Calendar => DatabaseLayoutPB::Calendar,
                    ViewLayoutPB::Grid => DatabaseLayoutPB::Grid,
                    ViewLayoutPB::Document | ViewLayoutPB::Chat => {
                        return Err(FlowyError::not_support());
                    },
                };
                let name = params.name.to_string();
                let database_view_id = params.view_id.to_string();
                let database_parent_view_id = params.parent_view_id.to_string();
                self
                    .0
                    .create_linked_view(
                        name,
                        layout.into(),
                        database_params.database_id,
                        database_view_id,
                        database_parent_view_id,
                    )
                    .await?;
                Ok(None)
            },
        }
    }

    /// Create a database view with build-in data.
    /// If the ext contains the {"database_id": "xx"}, then it will link to
    /// the existing database. The data of the database will be shared within
    /// these references views.
    async fn create_default_view(
        &self,
        _user_id: i64,
        _parent_view_id: &str,
        view_id: &str,
        name: &str,
        layout: ViewLayout,
    ) -> Result<(), FlowyError> {
        let name = name.to_string();
        let data = match layout {
            ViewLayout::Grid => make_default_grid(view_id, &name),
            ViewLayout::Board => make_default_board(view_id, &name),
            ViewLayout::Calendar => make_default_calendar(view_id, &name),
            ViewLayout::Document | ViewLayout::Chat => {
                return Err(
                    FlowyError::internal().with_context(format!("Can't handle {:?} layout type", layout)),
                );
            },
        };
        let result = self.0.import_database(data).await;
        match result {
            Ok(_) => Ok(()),
            Err(err) => {
                if err.is_already_exists() {
                    Ok(())
                } else {
                    Err(err)
                }
            },
        }
    }

    async fn import_from_bytes(
        &self,
        _uid: i64,
        view_id: &str,
        _name: &str,
        import_type: ImportType,
        bytes: Vec<u8>,
    ) -> Result<Vec<ImportedData>, FlowyError> {
        let format = match import_type {
            ImportType::CSV => CSVFormat::Original,
            ImportType::AFDatabase => CSVFormat::META,
            _ => CSVFormat::Original,
        };
        let content = tokio::task::spawn_blocking(move || {
            String::from_utf8(bytes).map_err(|err| FlowyError::internal().with_context(err))
        })
            .await??;
        let result = self
            .0
            .import_csv(view_id.to_string(), content, format)
            .await?;
        Ok(
            result
                .encoded_collabs
                .into_iter()
                .map(|encoded| {
                    (
                        encoded.object_id,
                        encoded.collab_type,
                        encoded.encoded_collab,
                    )
                })
                .collect(),
        )
    }

    async fn import_from_file_path(
        &self,
        view_id: &str,
        _name: &str,
        path: String,
    ) -> Result<(), FlowyError> {
        let file_path = Path::new(&path);
        if !file_path.exists() {
            return Err(FlowyError::record_not_found().with_context("File not found"));
        }

        let data = tokio::fs::read(file_path).await?;
        let content =
            String::from_utf8(data).map_err(|e| FlowyError::invalid_data().with_context(e))?;
        let _ = self
            .0
            .import_csv(view_id.to_string(), content, CSVFormat::Original)
            .await?;
        Ok(())
    }

    async fn did_update_view(&self, old: &View, new: &View) -> Result<(), FlowyError> {
        let database_layout = match new.layout {
            ViewLayout::Document | ViewLayout::Chat => {
                return Err(FlowyError::internal().with_context("Can't handle document layout type"));
            },
            ViewLayout::Grid => DatabaseLayoutPB::Grid,
            ViewLayout::Board => DatabaseLayoutPB::Board,
            ViewLayout::Calendar => DatabaseLayoutPB::Calendar,
        };

        if old.layout != new.layout {
            self
                .0
                .update_database_layout(&new.id, database_layout)
                .await?;
            Ok(())
        } else {
            Ok(())
        }
    }

    fn name(&self) -> &str {
        "DatabaseFolderOperationHandler"
    }
}


#[derive(Debug, serde::Deserialize)]
struct CreateDatabaseExtParams {
    database_id: String,
}

impl CreateDatabaseExtParams {
    pub fn from_map(map: HashMap<String, String>) -> Option<Self> {
        let value = serde_json::to_value(map).ok()?;
        serde_json::from_value::<Self>(value).ok()
    }
}

