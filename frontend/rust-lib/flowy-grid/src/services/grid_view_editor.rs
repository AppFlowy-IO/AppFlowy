use flowy_error::{FlowyError, FlowyResult};

use crate::entities::{
    CreateRowParams, GridFilterConfiguration, GridLayout, GridSettingPB, GroupPB, GroupRowsChangesetPB, InsertedRowPB,
    RowPB,
};
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::group::{default_group_configuration, Group, GroupConfigurationDelegate, GroupService};
use flowy_grid_data_model::revision::{FieldRevision, GroupConfigurationRevision, RowRevision};
use flowy_revision::{RevisionCloudService, RevisionManager, RevisionObjectBuilder};
use flowy_sync::client_grid::{GridViewRevisionChangeset, GridViewRevisionPad};
use flowy_sync::entities::revision::Revision;

use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::services::setting::make_grid_setting;
use flowy_sync::entities::grid::GridSettingChangesetParams;
use lib_infra::future::{wrap_future, AFFuture, FutureResult};
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait GridViewRevisionDelegate: Send + Sync + 'static {
    fn get_field_revs(&self) -> AFFuture<Vec<Arc<FieldRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> AFFuture<Option<Arc<FieldRevision>>>;
}

pub trait GridViewRevisionRowDataSource: Send + Sync + 'static {
    fn row_revs(&self) -> AFFuture<Vec<Arc<RowRevision>>>;
}

#[allow(dead_code)]
pub struct GridViewRevisionEditor {
    user_id: String,
    view_id: String,
    pad: Arc<RwLock<GridViewRevisionPad>>,
    rev_manager: Arc<RevisionManager>,
    delegate: Arc<dyn GridViewRevisionDelegate>,
    data_source: Arc<dyn GridViewRevisionRowDataSource>,
    group_service: Arc<RwLock<GroupService>>,
    groups: Arc<RwLock<Vec<Group>>>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
}

impl GridViewRevisionEditor {
    pub(crate) async fn new<Delegate, DataSource>(
        user_id: &str,
        token: &str,
        view_id: String,
        delegate: Delegate,
        data_source: DataSource,
        scheduler: Arc<dyn GridServiceTaskScheduler>,
        mut rev_manager: RevisionManager,
    ) -> FlowyResult<Self>
    where
        Delegate: GridViewRevisionDelegate,
        DataSource: GridViewRevisionRowDataSource,
    {
        let cloud = Arc::new(GridViewRevisionCloudService {
            token: token.to_owned(),
        });
        let view_revision_pad = rev_manager.load::<GridViewRevisionPadBuilder>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(view_revision_pad));
        let rev_manager = Arc::new(rev_manager);
        let group_service = GroupService::new(Box::new(pad.clone())).await;
        let user_id = user_id.to_owned();
        let groups = Arc::new(RwLock::new(vec![]));
        Ok(Self {
            pad,
            user_id,
            view_id,
            rev_manager,
            scheduler,
            groups,
            delegate: Arc::new(delegate),
            data_source: Arc::new(data_source),
            group_service: Arc::new(RwLock::new(group_service)),
        })
    }

    pub(crate) async fn update_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        match params.layout {
            GridLayout::Table => {
                // Table can be grouped too
            }
            GridLayout::Board => match params.group_id.as_ref() {
                None => {}
                Some(group_id) => {
                    self.group_service
                        .read()
                        .await
                        .update_row(row_rev, group_id, |field_id| self.delegate.get_field_rev(&field_id))
                        .await;
                }
            },
        }
    }

    pub(crate) async fn did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        // Send the group notification if the current view has groups
        match params.group_id.as_ref() {
            None => {}
            Some(group_id) => {
                let inserted_row = InsertedRowPB {
                    row: row_pb.clone(),
                    index: None,
                };
                let changeset = GroupRowsChangesetPB::insert(group_id.clone(), vec![inserted_row]);
                self.notify_did_update_group(changeset).await;
            }
        }
    }

    pub(crate) async fn did_delete_row(&self, row_id: &str) {
        // Send the group notification if the current view has groups;
        match self.group_id_of_row(row_id).await {
            None => {}
            Some(group_id) => {
                let changeset = GroupRowsChangesetPB::delete(group_id, vec![row_id.to_owned()]);
                self.notify_did_update_group(changeset).await;
            }
        }
    }

    async fn group_id_of_row(&self, row_id: &str) -> Option<String> {
        let read_guard = self.groups.read().await;
        for group in read_guard.iter() {
            if group.rows.iter().any(|row| row.id == row_id) {
                return Some(group.id.clone());
            }
        }

        None
    }

    pub(crate) async fn load_groups(&self) -> FlowyResult<Vec<GroupPB>> {
        let field_revs = self.delegate.get_field_revs().await;
        let row_revs = self.data_source.row_revs().await;

        //
        let mut write_guard = self.group_service.write().await;
        match write_guard.load_groups(&field_revs, row_revs).await {
            None => Ok(vec![]),
            Some(groups) => {
                *self.groups.write().await = groups.clone();
                Ok(groups.into_iter().map(GroupPB::from).collect())
            }
        }
    }

    pub(crate) async fn get_setting(&self) -> GridSettingPB {
        let field_revs = self.delegate.get_field_revs().await;
        let grid_setting = make_grid_setting(self.pad.read().await.get_setting_rev(), &field_revs);
        grid_setting
    }

    pub(crate) async fn update_setting(&self, changeset: GridSettingChangesetParams) -> FlowyResult<()> {
        let _ = self.modify(|pad| Ok(pad.update_setting(changeset)?)).await;
        Ok(())
    }

    pub(crate) async fn get_filters(&self) -> Vec<GridFilterConfiguration> {
        let field_revs = self.delegate.get_field_revs().await;
        match self.pad.read().await.get_setting_rev().get_all_filters(&field_revs) {
            None => vec![],
            Some(filters) => filters
                .into_values()
                .flatten()
                .map(|filter| GridFilterConfiguration::from(filter.as_ref()))
                .collect(),
        }
    }

    async fn notify_did_update_group(&self, changeset: GroupRowsChangesetPB) {
        send_dart_notification(&changeset.group_id, GridNotification::DidUpdateGroup)
            .payload(changeset)
            .send();
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridViewRevisionPad) -> FlowyResult<Option<GridViewRevisionChangeset>>,
    {
        let mut write_guard = self.pad.write().await;
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = self.apply_change(change).await?;
            }
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridViewRevisionChangeset) -> FlowyResult<()> {
        let GridViewRevisionChangeset { delta, md5 } = change;
        let user_id = self.user_id.clone();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.json_bytes();
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &user_id,
            md5,
        );
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(())
    }
}

struct GridViewRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridViewRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridViewRevisionPadBuilder();
impl RevisionObjectBuilder for GridViewRevisionPadBuilder {
    type Output = GridViewRevisionPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridViewRevisionPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}

impl GroupConfigurationDelegate for Arc<RwLock<GridViewRevisionPad>> {
    fn get_group_configuration(&self, field_rev: Arc<FieldRevision>) -> AFFuture<GroupConfigurationRevision> {
        let view_pad = self.clone();
        wrap_future(async move {
            let grid_pad = view_pad.read().await;
            let configurations = grid_pad.get_groups(&field_rev.id, &field_rev.field_type_rev);
            match configurations {
                None => default_group_configuration(&field_rev),
                Some(mut configurations) => {
                    assert_eq!(configurations.len(), 1);
                    (&*configurations.pop().unwrap()).clone()
                }
            }
        })
    }
}
