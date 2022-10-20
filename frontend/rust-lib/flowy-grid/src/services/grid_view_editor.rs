use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::{
    CreateRowParams, DeleteFilterParams, DeleteGroupParams, GridFilterConfigurationPB, GridGroupConfigurationPB,
    GridLayout, GridLayoutPB, GridSettingPB, GroupChangesetPB, GroupPB, GroupViewChangesetPB, InsertFilterParams,
    InsertGroupParams, InsertedGroupPB, InsertedRowPB, MoveGroupParams, RepeatedGridFilterConfigurationPB,
    RepeatedGridGroupConfigurationPB, RowPB,
};
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::grid_view_manager::{GridViewFieldDelegate, GridViewRowDelegate};
use crate::services::group::{
    default_group_configuration, find_group_field, make_group_controller, GroupConfigurationReader,
    GroupConfigurationWriter, GroupController, MoveGroupRowContext,
};
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{
    gen_grid_filter_id, FieldRevision, FieldTypeRevision, FilterConfigurationRevision, GroupConfigurationRevision,
    RowChangeset, RowRevision,
};
use flowy_revision::{
    RevisionCloudService, RevisionCompress, RevisionManager, RevisionObjectDeserializer, RevisionObjectSerializer,
};
use flowy_sync::client_grid::{GridViewRevisionChangeset, GridViewRevisionPad};
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_operations_from_revisions;
use lib_infra::future::{wrap_future, AFFuture, FutureResult};
use lib_ot::core::EmptyAttributes;
use std::future::Future;
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
    group_controller: Arc<RwLock<Box<dyn GroupController>>>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
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
        let view_revision_pad = rev_manager.load::<GridViewRevisionSerde>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(view_revision_pad));
        let rev_manager = Arc::new(rev_manager);
        let group_controller = new_group_controller(
            user_id.to_owned(),
            view_id.clone(),
            pad.clone(),
            rev_manager.clone(),
            field_delegate.clone(),
            row_delegate.clone(),
        )
        .await?;
        let user_id = user_id.to_owned();
        Ok(Self {
            pad,
            user_id,
            view_id,
            rev_manager,
            scheduler,
            field_delegate,
            row_delegate,
            group_controller: Arc::new(RwLock::new(group_controller)),
        })
    }

    pub(crate) async fn duplicate_view_data(&self) -> FlowyResult<String> {
        let json_str = self.pad.read().await.json_str()?;
        Ok(json_str)
    }

    pub(crate) async fn will_create_view_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        if params.group_id.is_none() {
            return;
        }
        let group_id = params.group_id.as_ref().unwrap();
        let _ = self
            .mut_group_controller(|group_controller, field_rev| {
                group_controller.will_create_row(row_rev, &field_rev, group_id);
                Ok(())
            })
            .await;
    }

    pub(crate) async fn did_create_view_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        // Send the group notification if the current view has groups
        match params.group_id.as_ref() {
            None => {}
            Some(group_id) => {
                let index = match params.start_row_id {
                    None => Some(0),
                    Some(_) => None,
                };

                self.group_controller.write().await.did_create_row(row_pb, group_id);
                let inserted_row = InsertedRowPB {
                    row: row_pb.clone(),
                    index,
                    is_new: true,
                };
                let changeset = GroupChangesetPB::insert(group_id.clone(), vec![inserted_row]);
                self.notify_did_update_group(changeset).await;
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all)]
    pub(crate) async fn did_delete_view_row(&self, row_rev: &RowRevision) {
        // Send the group notification if the current view has groups;
        let changesets = self
            .mut_group_controller(|group_controller, field_rev| {
                group_controller.did_delete_delete_row(row_rev, &field_rev)
            })
            .await;

        tracing::trace!("Delete row in view changeset: {:?}", changesets);
        if let Some(changesets) = changesets {
            for changeset in changesets {
                self.notify_did_update_group(changeset).await;
            }
        }
    }

    pub(crate) async fn did_update_view_cell(&self, row_rev: &RowRevision) {
        let changesets = self
            .mut_group_controller(|group_controller, field_rev| {
                group_controller.did_update_group_row(row_rev, &field_rev)
            })
            .await;

        if let Some(changesets) = changesets {
            for changeset in changesets {
                self.notify_did_update_group(changeset).await;
            }
        }
    }

    pub(crate) async fn move_view_group_row(
        &self,
        row_rev: &RowRevision,
        row_changeset: &mut RowChangeset,
        to_group_id: &str,
        to_row_id: Option<String>,
    ) -> Vec<GroupChangesetPB> {
        let changesets = self
            .mut_group_controller(|group_controller, field_rev| {
                let move_row_context = MoveGroupRowContext {
                    row_rev,
                    row_changeset,
                    field_rev: field_rev.as_ref(),
                    to_group_id,
                    to_row_id,
                };

                let changesets = group_controller.move_group_row(move_row_context)?;
                Ok(changesets)
            })
            .await;

        changesets.unwrap_or_default()
    }
    /// Only call once after grid view editor initialized
    #[tracing::instrument(level = "trace", skip(self))]
    pub(crate) async fn load_view_groups(&self) -> FlowyResult<Vec<GroupPB>> {
        let groups = self.group_controller.read().await.groups();
        tracing::trace!("Number of groups: {}", groups.len());
        Ok(groups.into_iter().map(GroupPB::from).collect())
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub(crate) async fn move_view_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
        let _ = self
            .group_controller
            .write()
            .await
            .move_group(&params.from_group_id, &params.to_group_id)?;
        match self.group_controller.read().await.get_group(&params.from_group_id) {
            None => tracing::warn!("Can not find the group with id: {}", params.from_group_id),
            Some((index, group)) => {
                let inserted_group = InsertedGroupPB {
                    group: GroupPB::from(group),
                    index: index as i32,
                };

                let changeset = GroupViewChangesetPB {
                    view_id: self.view_id.clone(),
                    inserted_groups: vec![inserted_group],
                    deleted_groups: vec![params.from_group_id.clone()],
                    update_groups: vec![],
                    new_groups: vec![],
                };

                self.notify_did_update_view(changeset).await;
            }
        }
        Ok(())
    }

    pub(crate) async fn group_id(&self) -> String {
        self.group_controller.read().await.field_id().to_owned()
    }

    pub(crate) async fn get_view_setting(&self) -> GridSettingPB {
        let field_revs = self.field_delegate.get_field_revs().await;
        let grid_setting = make_grid_setting(&*self.pad.read().await, &field_revs);
        grid_setting
    }

    pub(crate) async fn get_view_filters(&self) -> Vec<GridFilterConfigurationPB> {
        let field_revs = self.field_delegate.get_field_revs().await;
        match self.pad.read().await.get_all_filters(&field_revs) {
            None => vec![],
            Some(filters) => filters
                .into_values()
                .flatten()
                .map(|filter| GridFilterConfigurationPB::from(filter.as_ref()))
                .collect(),
        }
    }

    /// Initialize new group when grouping by a new field
    ///
    pub(crate) async fn initialize_new_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
        if let Some(field_rev) = self.field_delegate.get_field_rev(&params.field_id).await {
            let _ = self
                .modify(|pad| {
                    let configuration = default_group_configuration(&field_rev);
                    let changeset = pad.insert_or_update_group_configuration(
                        &params.field_id,
                        &params.field_type_rev,
                        configuration,
                    )?;
                    Ok(changeset)
                })
                .await?;
        }
        if self.group_controller.read().await.field_id() != params.field_id {
            let _ = self.group_by_view_field(&params.field_id).await?;
            self.notify_did_update_setting().await;
        }
        Ok(())
    }

    pub(crate) async fn delete_view_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
        self.modify(|pad| {
            let changeset = pad.delete_filter(&params.field_id, &params.field_type_rev, &params.group_id)?;
            Ok(changeset)
        })
        .await
    }

    pub(crate) async fn insert_view_filter(&self, params: InsertFilterParams) -> FlowyResult<()> {
        self.modify(|pad| {
            let filter_rev = FilterConfigurationRevision {
                id: gen_grid_filter_id(),
                field_id: params.field_id.clone(),
                condition: params.condition,
                content: params.content,
            };
            let changeset = pad.insert_filter(&params.field_id, &params.field_type_rev, filter_rev)?;
            Ok(changeset)
        })
        .await
    }

    pub(crate) async fn delete_view_filter(&self, delete_filter: DeleteFilterParams) -> FlowyResult<()> {
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
    #[tracing::instrument(level = "trace", skip_all, err)]
    pub(crate) async fn did_update_view_field(&self, _field_id: &str) -> FlowyResult<()> {
        // Do nothing
        Ok(())
    }

    ///
    ///
    /// # Arguments
    ///
    /// * `field_id`:
    ///
    #[tracing::instrument(level = "debug", skip_all, err)]
    pub(crate) async fn group_by_view_field(&self, field_id: &str) -> FlowyResult<()> {
        if let Some(field_rev) = self.field_delegate.get_field_rev(field_id).await {
            let new_group_controller = new_group_controller_with_field_rev(
                self.user_id.clone(),
                self.view_id.clone(),
                self.pad.clone(),
                self.rev_manager.clone(),
                field_rev,
                self.row_delegate.clone(),
            )
            .await?;

            let new_groups = new_group_controller.groups().into_iter().map(GroupPB::from).collect();

            *self.group_controller.write().await = new_group_controller;
            let changeset = GroupViewChangesetPB {
                view_id: self.view_id.clone(),
                new_groups,
                ..Default::default()
            };

            debug_assert!(!changeset.is_empty());
            if !changeset.is_empty() {
                send_dart_notification(&changeset.view_id, GridNotification::DidGroupByNewField)
                    .payload(changeset)
                    .send();
            }
        }
        Ok(())
    }

    async fn notify_did_update_setting(&self) {
        let setting = self.get_view_setting().await;
        send_dart_notification(&self.view_id, GridNotification::DidUpdateGridSetting)
            .payload(setting)
            .send();
    }

    pub async fn notify_did_update_group(&self, changeset: GroupChangesetPB) {
        send_dart_notification(&changeset.group_id, GridNotification::DidUpdateGroup)
            .payload(changeset)
            .send();
    }

    async fn notify_did_update_view(&self, changeset: GroupViewChangesetPB) {
        send_dart_notification(&self.view_id, GridNotification::DidUpdateGroupView)
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
                let _ = apply_change(&self.user_id, self.rev_manager.clone(), change).await?;
            }
        }
        Ok(())
    }

    async fn mut_group_controller<F, T>(&self, f: F) -> Option<T>
    where
        F: FnOnce(&mut Box<dyn GroupController>, Arc<FieldRevision>) -> FlowyResult<T>,
    {
        let group_field_id = self.group_controller.read().await.field_id().to_owned();
        match self.field_delegate.get_field_rev(&group_field_id).await {
            None => None,
            Some(field_rev) => {
                let mut write_guard = self.group_controller.write().await;
                f(&mut write_guard, field_rev).ok()
            }
        }
    }

    #[allow(dead_code)]
    async fn async_mut_group_controller<F, O, T>(&self, f: F) -> Option<T>
    where
        F: FnOnce(Arc<RwLock<Box<dyn GroupController>>>, Arc<FieldRevision>) -> O,
        O: Future<Output = FlowyResult<T>> + Sync + 'static,
    {
        let group_field_id = self.group_controller.read().await.field_id().to_owned();
        match self.field_delegate.get_field_rev(&group_field_id).await {
            None => None,
            Some(field_rev) => {
                let _write_guard = self.group_controller.write().await;
                f(self.group_controller.clone(), field_rev).await.ok()
            }
        }
    }
}

async fn new_group_controller(
    user_id: String,
    view_id: String,
    view_rev_pad: Arc<RwLock<GridViewRevisionPad>>,
    rev_manager: Arc<RevisionManager>,
    field_delegate: Arc<dyn GridViewFieldDelegate>,
    row_delegate: Arc<dyn GridViewRowDelegate>,
) -> FlowyResult<Box<dyn GroupController>> {
    let configuration_reader = GroupConfigurationReaderImpl(view_rev_pad.clone());
    let field_revs = field_delegate.get_field_revs().await;
    let layout = view_rev_pad.read().await.layout();
    // Read the group field or find a new group field
    let field_rev = configuration_reader
        .get_configuration()
        .await
        .and_then(|configuration| {
            field_revs
                .iter()
                .find(|field_rev| field_rev.id == configuration.field_id)
                .cloned()
        })
        .unwrap_or_else(|| find_group_field(&field_revs, &layout).unwrap());

    new_group_controller_with_field_rev(user_id, view_id, view_rev_pad, rev_manager, field_rev, row_delegate).await
}

/// Returns a [GroupController]  
///
/// # Arguments
///
/// * `user_id`:
/// * `view_id`:
/// * `view_rev_pad`:
/// * `rev_manager`:
/// * `field_rev`:
/// * `row_delegate`:
///
async fn new_group_controller_with_field_rev(
    user_id: String,
    view_id: String,
    view_rev_pad: Arc<RwLock<GridViewRevisionPad>>,
    rev_manager: Arc<RevisionManager>,
    field_rev: Arc<FieldRevision>,
    row_delegate: Arc<dyn GridViewRowDelegate>,
) -> FlowyResult<Box<dyn GroupController>> {
    let configuration_reader = GroupConfigurationReaderImpl(view_rev_pad.clone());
    let configuration_writer = GroupConfigurationWriterImpl {
        user_id,
        rev_manager,
        view_pad: view_rev_pad,
    };
    let row_revs = row_delegate.gv_row_revs().await;
    make_group_controller(view_id, field_rev, row_revs, configuration_reader, configuration_writer).await
}

async fn apply_change(
    user_id: &str,
    rev_manager: Arc<RevisionManager>,
    change: GridViewRevisionChangeset,
) -> FlowyResult<()> {
    let GridViewRevisionChangeset { operations: delta, md5 } = change;
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

pub struct GridViewRevisionSerde();
impl RevisionObjectDeserializer for GridViewRevisionSerde {
    type Output = GridViewRevisionPad;

    fn deserialize_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridViewRevisionPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}

impl RevisionObjectSerializer for GridViewRevisionSerde {
    fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let operations = make_operations_from_revisions::<EmptyAttributes>(revisions)?;
        Ok(operations.json_bytes())
    }
}

pub struct GridViewRevisionCompress();
impl RevisionCompress for GridViewRevisionCompress {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        GridViewRevisionSerde::combine_revisions(revisions)
    }
}

struct GroupConfigurationReaderImpl(Arc<RwLock<GridViewRevisionPad>>);

impl GroupConfigurationReader for GroupConfigurationReaderImpl {
    fn get_configuration(&self) -> AFFuture<Option<Arc<GroupConfigurationRevision>>> {
        let view_pad = self.0.clone();
        wrap_future(async move {
            let mut groups = view_pad.read().await.get_all_groups();
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
    fn save_configuration(
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
            let changeset = view_pad.write().await.insert_or_update_group_configuration(
                &field_id,
                &field_type,
                group_configuration,
            )?;

            if let Some(changeset) = changeset {
                let _ = apply_change(&user_id, rev_manager, changeset).await?;
            }
            Ok(())
        })
    }
}

pub fn make_grid_setting(view_pad: &GridViewRevisionPad, field_revs: &[Arc<FieldRevision>]) -> GridSettingPB {
    let layout_type: GridLayout = view_pad.layout.clone().into();
    let filter_configurations = view_pad
        .get_all_filters(field_revs)
        .map(|filters_by_field_id| {
            filters_by_field_id
                .into_iter()
                .flat_map(|(_, v)| {
                    let repeated_filter: RepeatedGridFilterConfigurationPB = v.into();
                    repeated_filter.items
                })
                .collect::<Vec<GridFilterConfigurationPB>>()
        })
        .unwrap_or_default();

    let group_configurations = view_pad
        .get_groups_by_field_revs(field_revs)
        .map(|groups_by_field_id| {
            groups_by_field_id
                .into_iter()
                .flat_map(|(_, v)| {
                    let repeated_group: RepeatedGridGroupConfigurationPB = v.into();
                    repeated_group.items
                })
                .collect::<Vec<GridGroupConfigurationPB>>()
        })
        .unwrap_or_default();

    GridSettingPB {
        layouts: GridLayoutPB::all(),
        layout_type,
        filter_configurations: filter_configurations.into(),
        group_configurations: group_configurations.into(),
    }
}

#[cfg(test)]
mod tests {
    use lib_ot::core::Delta;

    #[test]
    fn test() {
        let s1 = r#"[{"insert":"{\"view_id\":\"fTURELffPr\",\"grid_id\":\"fTURELffPr\",\"layout\":0,\"filters\":[],\"groups\":[]}"}]"#;
        let _delta_1 = Delta::from_json(s1).unwrap();

        let s2 = r#"[{"retain":195},{"insert":"{\\\"group_id\\\":\\\"wD9i\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"xZtv\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"tFV2\\\",\\\"visible\\\":true}"},{"retain":10}]"#;
        let _delta_2 = Delta::from_json(s2).unwrap();
    }
}
