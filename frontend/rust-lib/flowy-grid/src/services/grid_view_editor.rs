use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::{
    CreateFilterParams, CreateRowParams, DeleteFilterParams, GridFilterConfiguration, GridLayout, GridLayoutPB,
    GridSettingPB, GroupPB, GroupRowsChangesetPB, GroupViewChangesetPB, InsertedGroupPB, InsertedRowPB,
    MoveGroupParams, RepeatedGridConfigurationFilterPB, RepeatedGridGroupConfigurationPB, RowPB,
};
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::grid_view_manager::{GridViewFieldDelegate, GridViewRowDelegate};
use crate::services::group::{GroupConfigurationReader, GroupConfigurationWriter, GroupService};
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{
    gen_grid_filter_id, FieldRevision, FieldTypeRevision, FilterConfigurationRevision, GroupConfigurationRevision,
    RowChangeset, RowRevision,
};
use flowy_revision::{RevisionCloudService, RevisionManager, RevisionObjectBuilder};
use flowy_sync::client_grid::{GridViewRevisionChangeset, GridViewRevisionPad};
use flowy_sync::entities::revision::Revision;
use lib_infra::future::{wrap_future, AFFuture, FutureResult};
use std::collections::HashMap;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::sync::RwLock;

#[allow(dead_code)]
pub struct GridViewRevisionEditor {
    user_id: String,
    view_id: String,
    pad: Arc<RwLock<GridViewRevisionPad>>,
    rev_manager: Arc<RevisionManager>,
    field_delegate: Arc<dyn GridViewFieldDelegate>,
    row_delegate: Arc<dyn GridViewRowDelegate>,
    group_service: Arc<RwLock<GroupService>>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
    did_load_group: AtomicBool,
}

impl GridViewRevisionEditor {
    #[tracing::instrument(level = "trace", skip_all, err)]
    pub(crate) async fn new(
        user_id: &str,
        token: &str,
        view_id: String,
        field_delegate: Arc<dyn GridViewFieldDelegate>,
        row_delegate: Arc<dyn GridViewRowDelegate>,
        scheduler: Arc<dyn GridServiceTaskScheduler>,
        mut rev_manager: RevisionManager,
    ) -> FlowyResult<Self> {
        let cloud = Arc::new(GridViewRevisionCloudService {
            token: token.to_owned(),
        });
        let view_revision_pad = rev_manager.load::<GridViewRevisionPadBuilder>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(view_revision_pad));
        let rev_manager = Arc::new(rev_manager);

        let configuration_reader = GroupConfigurationReaderImpl(pad.clone());
        let configuration_writer = GroupConfigurationWriterImpl {
            user_id: user_id.to_owned(),
            rev_manager: rev_manager.clone(),
            view_pad: pad.clone(),
        };
        let group_service = GroupService::new(configuration_reader, configuration_writer).await;
        let user_id = user_id.to_owned();
        let did_load_group = AtomicBool::new(false);
        Ok(Self {
            pad,
            user_id,
            view_id,
            rev_manager,
            scheduler,
            field_delegate,
            row_delegate,
            group_service: Arc::new(RwLock::new(group_service)),
            did_load_group,
        })
    }

    pub(crate) async fn will_create_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        match params.group_id.as_ref() {
            None => {}
            Some(group_id) => {
                self.group_service
                    .write()
                    .await
                    .will_create_row(row_rev, group_id, |field_id| {
                        self.field_delegate.get_field_rev(&field_id)
                    })
                    .await;
            }
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
                self.notify_did_update_group_rows(changeset).await;
            }
        }
    }

    pub(crate) async fn did_delete_row(&self, row_rev: &RowRevision) {
        // Send the group notification if the current view has groups;
        if let Some(changesets) = self
            .group_service
            .write()
            .await
            .did_delete_row(row_rev, |field_id| self.field_delegate.get_field_rev(&field_id))
            .await
        {
            for changeset in changesets {
                self.notify_did_update_group_rows(changeset).await;
            }
        }
    }

    pub(crate) async fn did_update_row(&self, row_rev: &RowRevision) {
        if let Some(changesets) = self
            .group_service
            .write()
            .await
            .did_update_row(row_rev, |field_id| self.field_delegate.get_field_rev(&field_id))
            .await
        {
            for changeset in changesets {
                self.notify_did_update_group_rows(changeset).await;
            }
        }
    }

    pub(crate) async fn move_group_row(
        &self,
        row_rev: &RowRevision,
        row_changeset: &mut RowChangeset,
        to_group_id: &str,
        to_row_id: Option<String>,
    ) {
        if let Some(changesets) = self
            .group_service
            .write()
            .await
            .move_group_row(row_rev, row_changeset, to_group_id, to_row_id, |field_id| {
                self.field_delegate.get_field_rev(&field_id)
            })
            .await
        {
            for changeset in changesets {
                self.notify_did_update_group_rows(changeset).await;
            }
        }
    }

    #[tracing::instrument(level = "trace", skip(self))]
    pub(crate) async fn load_groups(&self) -> FlowyResult<Vec<GroupPB>> {
        let groups = if !self.did_load_group.load(Ordering::SeqCst) {
            self.did_load_group.store(true, Ordering::SeqCst);
            let field_revs = self.field_delegate.get_field_revs().await;
            let row_revs = self.row_delegate.gv_row_revs().await;

            match self
                .group_service
                .write()
                .await
                .load_groups(&field_revs, row_revs)
                .await
            {
                None => vec![],
                Some(groups) => groups,
            }
        } else {
            self.group_service.read().await.groups().await
        };

        tracing::trace!("Number of groups: {}", groups.len());
        Ok(groups.into_iter().map(GroupPB::from).collect())
    }

    pub(crate) async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
        let _ = self
            .group_service
            .write()
            .await
            .move_group(&params.from_group_id, &params.to_group_id)
            .await?;

        match self.group_service.read().await.get_group(&params.from_group_id).await {
            None => {}
            Some((index, group)) => {
                let inserted_group = InsertedGroupPB {
                    group: GroupPB::from(group),
                    index: index as i32,
                };

                let changeset = GroupViewChangesetPB {
                    view_id: "".to_string(),
                    inserted_groups: vec![inserted_group],
                    deleted_groups: vec![params.from_group_id.clone()],
                };

                self.notify_did_update_view(changeset).await;
            }
        }
        Ok(())
    }

    pub(crate) async fn get_setting(&self) -> GridSettingPB {
        let field_revs = self.field_delegate.get_field_revs().await;
        let grid_setting = make_grid_setting(&*self.pad.read().await, &field_revs);
        grid_setting
    }

    pub(crate) async fn get_filters(&self) -> Vec<GridFilterConfiguration> {
        let field_revs = self.field_delegate.get_field_revs().await;
        match self.pad.read().await.get_all_filters(&field_revs) {
            None => vec![],
            Some(filters) => filters
                .into_values()
                .flatten()
                .map(|filter| GridFilterConfiguration::from(filter.as_ref()))
                .collect(),
        }
    }

    pub(crate) async fn insert_filter(&self, insert_filter: CreateFilterParams) -> FlowyResult<()> {
        self.modify(|pad| {
            let filter_rev = FilterConfigurationRevision {
                id: gen_grid_filter_id(),
                field_id: insert_filter.field_id.clone(),
                condition: insert_filter.condition,
                content: insert_filter.content,
            };
            let changeset = pad.insert_filter(&insert_filter.field_id, &insert_filter.field_type_rev, filter_rev)?;
            Ok(changeset)
        })
        .await
    }

    pub(crate) async fn delete_filter(&self, delete_filter: DeleteFilterParams) -> FlowyResult<()> {
        self.modify(|pad| {
            let changeset = pad.delete_filter(
                &delete_filter.field_id,
                &delete_filter.field_type_rev,
                &delete_filter.filter_id,
            )?;
            Ok(changeset)
        })
        .await
    }

    async fn notify_did_update_group_rows(&self, changeset: GroupRowsChangesetPB) {
        send_dart_notification(&changeset.group_id, GridNotification::DidUpdateGroup)
            .payload(changeset)
            .send();
    }

    async fn notify_did_update_view(&self, changeset: GroupViewChangesetPB) {
        send_dart_notification(&self.view_id, GridNotification::DidUpdateGroupView)
            .payload(changeset)
            .send();
    }

    #[allow(dead_code)]
    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridViewRevisionPad) -> FlowyResult<Option<GridViewRevisionChangeset>>,
    {
        let mut write_guard = self.pad.write().await;
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = apply_change(&self.user_id, self.rev_manager.clone(), change).await?;
            }
        }
        Ok(())
    }
}

async fn apply_change(
    user_id: &str,
    rev_manager: Arc<RevisionManager>,
    change: GridViewRevisionChangeset,
) -> FlowyResult<()> {
    let GridViewRevisionChangeset { delta, md5 } = change;
    let (base_rev_id, rev_id) = rev_manager.next_rev_id_pair();
    let delta_data = delta.json_bytes();
    let revision = Revision::new(&rev_manager.object_id, base_rev_id, rev_id, delta_data, user_id, md5);
    let _ = rev_manager.add_local_revision(&revision).await?;
    Ok(())
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

struct GroupConfigurationReaderImpl(Arc<RwLock<GridViewRevisionPad>>);

impl GroupConfigurationReader for GroupConfigurationReaderImpl {
    fn get_group_configuration(
        &self,
        field_rev: Arc<FieldRevision>,
    ) -> AFFuture<Option<Arc<GroupConfigurationRevision>>> {
        let view_pad = self.0.clone();
        wrap_future(async move {
            let mut groups = view_pad.read().await.groups.get_objects(&field_rev.id, &field_rev.ty)?;
            if groups.is_empty() {
                None
            } else {
                debug_assert_eq!(groups.len(), 1);
                Some(groups.pop().unwrap())
            }
        })
    }
}

struct GroupConfigurationWriterImpl {
    user_id: String,
    rev_manager: Arc<RevisionManager>,
    view_pad: Arc<RwLock<GridViewRevisionPad>>,
}

impl GroupConfigurationWriter for GroupConfigurationWriterImpl {
    fn save_group_configuration(
        &self,
        field_id: &str,
        field_type: FieldTypeRevision,
        group_configuration: GroupConfigurationRevision,
    ) -> AFFuture<FlowyResult<()>> {
        let user_id = self.user_id.clone();
        let rev_manager = self.rev_manager.clone();
        let view_pad = self.view_pad.clone();
        let field_id = field_id.to_owned();

        wrap_future(async move {
            let changeset = view_pad
                .write()
                .await
                .insert_group(&field_id, &field_type, group_configuration)?;

            if let Some(changeset) = changeset {
                let _ = apply_change(&user_id, rev_manager, changeset).await?;
            }
            Ok(())
        })
    }
}

pub fn make_grid_setting(view_pad: &GridViewRevisionPad, field_revs: &[Arc<FieldRevision>]) -> GridSettingPB {
    let current_layout_type: GridLayout = view_pad.layout.clone().into();
    let filters_by_field_id = view_pad
        .get_all_filters(field_revs)
        .map(|filters_by_field_id| {
            filters_by_field_id
                .into_iter()
                .map(|(k, v)| (k, v.into()))
                .collect::<HashMap<String, RepeatedGridConfigurationFilterPB>>()
        })
        .unwrap_or_default();
    let groups_by_field_id = view_pad
        .get_all_groups(field_revs)
        .map(|groups_by_field_id| {
            groups_by_field_id
                .into_iter()
                .map(|(k, v)| (k, v.into()))
                .collect::<HashMap<String, RepeatedGridGroupConfigurationPB>>()
        })
        .unwrap_or_default();

    GridSettingPB {
        layouts: GridLayoutPB::all(),
        current_layout_type,
        filter_configuration_by_field_id: filters_by_field_id,
        group_configuration_by_field_id: groups_by_field_id,
    }
}

#[cfg(test)]
mod tests {
    use lib_ot::core::TextDelta;

    #[test]
    fn test() {
        let s1 = r#"[{"insert":"{\"view_id\":\"fTURELffPr\",\"grid_id\":\"fTURELffPr\",\"layout\":0,\"filters\":[],\"groups\":[]}"}]"#;
        let _delta_1 = TextDelta::from_json(s1).unwrap();

        let s2 = r#"[{"retain":195},{"insert":"{\\\"group_id\\\":\\\"wD9i\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"xZtv\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"tFV2\\\",\\\"visible\\\":true}"},{"retain":10}]"#;
        let _delta_2 = TextDelta::from_json(s2).unwrap();
    }
}
