use crate::entities::revision::{md5, Revision};
use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_text_delta_from_revisions};
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, FilterConfigurationRevision, FilterConfigurationsByFieldId, GridViewRevision,
    GroupConfigurationRevision, GroupConfigurationsByFieldId, SortConfigurationsByFieldId,
};
use lib_ot::core::{OperationTransform, PhantomAttributes, TextDelta, TextDeltaBuilder};
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct GridViewRevisionPad {
    view: Arc<GridViewRevision>,
    delta: TextDelta,
}

impl std::ops::Deref for GridViewRevisionPad {
    type Target = GridViewRevision;

    fn deref(&self) -> &Self::Target {
        &self.view
    }
}

impl GridViewRevisionPad {
    pub fn new(grid_id: String) -> Self {
        let view = Arc::new(GridViewRevision::new(grid_id));
        let json = serde_json::to_string(&view).unwrap();
        let delta = TextDeltaBuilder::new().insert(&json).build();
        Self { view, delta }
    }

    pub fn from_delta(delta: TextDelta) -> CollaborateResult<Self> {
        let s = delta.content()?;
        let view: GridViewRevision = serde_json::from_str(&s).map_err(|e| {
            let msg = format!("Deserialize delta to GridViewRevision failed: {}", e);
            tracing::error!("{}", s);
            CollaborateError::internal().context(msg)
        })?;
        Ok(Self {
            view: Arc::new(view),
            delta,
        })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let delta: TextDelta = make_text_delta_from_revisions(revisions)?;
        Self::from_delta(delta)
    }

    pub fn get_all_groups(&self, field_revs: &[Arc<FieldRevision>]) -> Option<GroupConfigurationsByFieldId> {
        self.setting.groups.get_all_objects(field_revs)
    }

    pub fn get_groups(
        &self,
        field_id: &str,
        field_type_rev: &FieldTypeRevision,
    ) -> Option<Vec<Arc<GroupConfigurationRevision>>> {
        self.setting.groups.get_objects(field_id, field_type_rev)
    }

    pub fn insert_group(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        group_rev: GroupConfigurationRevision,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| {
            // only one group can be set
            view.setting.groups.remove_all();
            view.setting.groups.insert_object(field_id, field_type, group_rev);
            Ok(Some(()))
        })
    }

    pub fn delete_group(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        group_id: &str,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| {
            if let Some(groups) = view.setting.groups.get_mut_objects(field_id, field_type) {
                groups.retain(|group| group.id != group_id);
                Ok(Some(()))
            } else {
                Ok(None)
            }
        })
    }

    pub fn get_all_filters(&self, field_revs: &[Arc<FieldRevision>]) -> Option<FilterConfigurationsByFieldId> {
        self.setting.filters.get_all_objects(field_revs)
    }

    pub fn get_filters(
        &self,
        field_id: &str,
        field_type_rev: &FieldTypeRevision,
    ) -> Option<Vec<Arc<FilterConfigurationRevision>>> {
        self.setting.filters.get_objects(field_id, field_type_rev)
    }

    pub fn insert_filter(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        filter_rev: FilterConfigurationRevision,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| {
            view.setting.filters.insert_object(field_id, field_type, filter_rev);
            Ok(Some(()))
        })
    }

    pub fn delete_filter(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        filter_id: &str,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| {
            if let Some(filters) = view.setting.filters.get_mut_objects(field_id, field_type) {
                filters.retain(|filter| filter.id != filter_id);
                Ok(Some(()))
            } else {
                Ok(None)
            }
        })
    }

    pub fn get_all_sort(&self) -> Option<SortConfigurationsByFieldId> {
        None
    }

    pub fn json_str(&self) -> CollaborateResult<String> {
        make_grid_view_rev_json_str(&self.view)
    }

    fn modify<F>(&mut self, f: F) -> CollaborateResult<Option<GridViewRevisionChangeset>>
    where
        F: FnOnce(&mut GridViewRevision) -> CollaborateResult<Option<()>>,
    {
        let cloned_view = self.view.clone();
        match f(Arc::make_mut(&mut self.view))? {
            None => Ok(None),
            Some(_) => {
                let old = make_grid_view_rev_json_str(&cloned_view)?;
                let new = self.json_str()?;
                match cal_diff::<PhantomAttributes>(old, new) {
                    None => Ok(None),
                    Some(delta) => {
                        self.delta = self.delta.compose(&delta)?;
                        let md5 = md5(&self.delta.json_bytes());
                        Ok(Some(GridViewRevisionChangeset { delta, md5 }))
                    }
                }
            }
        }
    }
}

pub struct GridViewRevisionChangeset {
    pub delta: TextDelta,
    pub md5: String,
}

pub fn make_grid_view_rev_json_str(grid_revision: &GridViewRevision) -> CollaborateResult<String> {
    let json = serde_json::to_string(grid_revision)
        .map_err(|err| internal_error(format!("Serialize grid view to json str failed. {:?}", err)))?;
    Ok(json)
}
