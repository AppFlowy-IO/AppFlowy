use crate::entities::revision::{md5, Revision};
use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_text_delta_from_revisions};
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, FilterConfigurationRevision, FilterConfigurationsByFieldId, GridViewRevision,
    GroupConfigurationRevision, GroupConfigurationsByFieldId, LayoutRevision,
};
use lib_ot::core::{Delta, DeltaBuilder, EmptyAttributes, OperationTransform};
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct GridViewRevisionPad {
    view: Arc<GridViewRevision>,
    delta: Delta,
}

impl std::ops::Deref for GridViewRevisionPad {
    type Target = GridViewRevision;

    fn deref(&self) -> &Self::Target {
        &self.view
    }
}

impl GridViewRevisionPad {
    // For the moment, the view_id is equal to grid_id. The grid_id represents the database id.
    // A database can be referenced by multiple views.
    pub fn new(grid_id: String, view_id: String, layout: LayoutRevision) -> Self {
        let view = Arc::new(GridViewRevision::new(grid_id, view_id, layout));
        let json = serde_json::to_string(&view).unwrap();
        let delta = DeltaBuilder::new().insert(&json).build();
        Self { view, delta }
    }

    pub fn from_delta(view_id: &str, delta: Delta) -> CollaborateResult<Self> {
        if delta.is_empty() {
            return Ok(GridViewRevisionPad::new(
                view_id.to_owned(),
                view_id.to_owned(),
                LayoutRevision::Table,
            ));
        }
        let s = delta.content()?;
        let view: GridViewRevision = serde_json::from_str(&s).map_err(|e| {
            let msg = format!("Deserialize delta to GridViewRevision failed: {}", e);
            tracing::error!("parsing json: {}", s);
            CollaborateError::internal().context(msg)
        })?;
        Ok(Self {
            view: Arc::new(view),
            delta,
        })
    }

    pub fn from_revisions(view_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let delta: Delta = make_text_delta_from_revisions(revisions)?;
        Self::from_delta(view_id, delta)
    }

    pub fn get_groups_by_field_revs(&self, field_revs: &[Arc<FieldRevision>]) -> Option<GroupConfigurationsByFieldId> {
        self.groups.get_objects_by_field_revs(field_revs)
    }

    pub fn get_all_groups(&self) -> Vec<Arc<GroupConfigurationRevision>> {
        self.groups.get_all_objects()
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub fn insert_group(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        group_configuration_rev: GroupConfigurationRevision,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| {
            // Only save one group
            view.groups.clear();
            view.groups.add_object(field_id, field_type, group_configuration_rev);
            Ok(Some(()))
        })
    }

    #[tracing::instrument(level = "trace", skip_all)]
    pub fn contains_group(&self, field_id: &str, field_type: &FieldTypeRevision) -> bool {
        self.view.groups.get_objects(field_id, field_type).is_some()
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub fn with_mut_group<F: FnOnce(&mut GroupConfigurationRevision)>(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        configuration_id: &str,
        mut_configuration_fn: F,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| match view.groups.get_mut_objects(field_id, field_type) {
            None => Ok(None),
            Some(configurations_revs) => {
                for configuration_rev in configurations_revs {
                    if configuration_rev.id == configuration_id {
                        mut_configuration_fn(Arc::make_mut(configuration_rev));
                        return Ok(Some(()));
                    }
                }
                Ok(None)
            }
        })
    }

    pub fn delete_group(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        group_id: &str,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| {
            if let Some(groups) = view.groups.get_mut_objects(field_id, field_type) {
                groups.retain(|group| group.id != group_id);
                Ok(Some(()))
            } else {
                Ok(None)
            }
        })
    }

    pub fn get_all_filters(&self, field_revs: &[Arc<FieldRevision>]) -> Option<FilterConfigurationsByFieldId> {
        self.filters.get_objects_by_field_revs(field_revs)
    }

    pub fn get_filters(
        &self,
        field_id: &str,
        field_type_rev: &FieldTypeRevision,
    ) -> Option<Vec<Arc<FilterConfigurationRevision>>> {
        self.filters.get_objects(field_id, field_type_rev)
    }

    pub fn insert_filter(
        &mut self,
        field_id: &str,
        field_type: &FieldTypeRevision,
        filter_rev: FilterConfigurationRevision,
    ) -> CollaborateResult<Option<GridViewRevisionChangeset>> {
        self.modify(|view| {
            view.filters.add_object(field_id, field_type, filter_rev);
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
            if let Some(filters) = view.filters.get_mut_objects(field_id, field_type) {
                filters.retain(|filter| filter.id != filter_id);
                Ok(Some(()))
            } else {
                Ok(None)
            }
        })
    }

    pub fn json_str(&self) -> CollaborateResult<String> {
        make_grid_view_rev_json_str(&self.view)
    }

    pub fn layout(&self) -> LayoutRevision {
        self.layout.clone()
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
                match cal_diff::<EmptyAttributes>(old, new) {
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

#[derive(Debug)]
pub struct GridViewRevisionChangeset {
    pub delta: Delta,
    pub md5: String,
}

pub fn make_grid_view_rev_json_str(grid_revision: &GridViewRevision) -> CollaborateResult<String> {
    let json = serde_json::to_string(grid_revision)
        .map_err(|err| internal_error(format!("Serialize grid view to json str failed. {:?}", err)))?;
    Ok(json)
}

pub fn make_grid_view_delta(grid_view: &GridViewRevision) -> Delta {
    let json = serde_json::to_string(grid_view).unwrap();
    DeltaBuilder::new().insert(&json).build()
}
