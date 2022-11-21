use crate::entities::{FilterConfigurationPB, FilterPB, GridLayout, GridLayoutPB, GridSettingPB, GroupConfigurationPB};
use crate::services::filter::{FilterDelegate, FilterType};
use crate::services::group::{GroupConfigurationReader, GroupConfigurationWriter};
use crate::services::row::GridBlock;
use crate::services::view_editor::GridViewEditorDelegate;
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_error::{FlowyError, FlowyResult};
use flowy_http_model::revision::Revision;
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionMergeable, RevisionObjectDeserializer, RevisionObjectSerializer,
};
use flowy_sync::client_grid::{GridViewRevisionChangeset, GridViewRevisionPad};
use flowy_sync::util::make_operations_from_revisions;
use grid_rev_model::{FieldRevision, FieldTypeRevision, FilterRevision, GroupConfigurationRevision, RowRevision};
use lib_infra::future::{to_future, Fut, FutureResult};
use lib_ot::core::EmptyAttributes;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridViewRevisionCloudService {
    #[allow(dead_code)]
    pub(crate) token: String,
}

impl RevisionCloudService for GridViewRevisionCloudService {
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

pub(crate) struct GridViewRevisionSerde();
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

pub(crate) struct GridViewRevisionCompress();
impl RevisionMergeable for GridViewRevisionCompress {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        GridViewRevisionSerde::combine_revisions(revisions)
    }
}

pub(crate) struct GroupConfigurationReaderImpl(pub(crate) Arc<RwLock<GridViewRevisionPad>>);

impl GroupConfigurationReader for GroupConfigurationReaderImpl {
    fn get_configuration(&self) -> Fut<Option<Arc<GroupConfigurationRevision>>> {
        let view_pad = self.0.clone();
        to_future(async move {
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

pub(crate) struct GroupConfigurationWriterImpl {
    pub(crate) user_id: String,
    pub(crate) rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    pub(crate) view_pad: Arc<RwLock<GridViewRevisionPad>>,
}

impl GroupConfigurationWriter for GroupConfigurationWriterImpl {
    fn save_configuration(
        &self,
        field_id: &str,
        field_type: FieldTypeRevision,
        group_configuration: GroupConfigurationRevision,
    ) -> Fut<FlowyResult<()>> {
        let user_id = self.user_id.clone();
        let rev_manager = self.rev_manager.clone();
        let view_pad = self.view_pad.clone();
        let field_id = field_id.to_owned();

        to_future(async move {
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

pub(crate) async fn apply_change(
    _user_id: &str,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    change: GridViewRevisionChangeset,
) -> FlowyResult<()> {
    let GridViewRevisionChangeset { operations: delta, md5 } = change;
    let (base_rev_id, rev_id) = rev_manager.next_rev_id_pair();
    let delta_data = delta.json_bytes();
    let revision = Revision::new(&rev_manager.object_id, base_rev_id, rev_id, delta_data, md5);
    let _ = rev_manager.add_local_revision(&revision).await?;
    Ok(())
}

pub fn make_grid_setting(view_pad: &GridViewRevisionPad, field_revs: &[Arc<FieldRevision>]) -> GridSettingPB {
    let layout_type: GridLayout = view_pad.layout.clone().into();
    let filter_configurations = view_pad.get_all_filters(field_revs);
    let group_configurations = view_pad.get_groups_by_field_revs(field_revs);
    GridSettingPB {
        layouts: GridLayoutPB::all(),
        layout_type,
        filter_configurations: filter_configurations.into(),
        group_configurations: group_configurations.into(),
    }
}

pub(crate) struct GridViewFilterDelegateImpl {
    pub(crate) editor_delegate: Arc<dyn GridViewEditorDelegate>,
    pub(crate) view_revision_pad: Arc<RwLock<GridViewRevisionPad>>,
}

impl FilterDelegate for GridViewFilterDelegateImpl {
    fn get_filter_rev(&self, filter_id: FilterType) -> Fut<Vec<Arc<FilterRevision>>> {
        let pad = self.view_revision_pad.clone();
        to_future(async move {
            let field_type_rev: FieldTypeRevision = filter_id.field_type.into();
            pad.read().await.get_filters(&filter_id.field_id, &field_type_rev)
        })
    }

    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>> {
        self.editor_delegate.get_field_rev(field_id)
    }

    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>> {
        self.editor_delegate.get_field_revs(field_ids)
    }

    fn get_blocks(&self) -> Fut<Vec<GridBlock>> {
        self.editor_delegate.get_blocks()
    }

    fn get_row_rev(&self, row_id: &str) -> Fut<Option<Arc<RowRevision>>> {
        self.editor_delegate.get_row_rev(row_id)
    }
}
