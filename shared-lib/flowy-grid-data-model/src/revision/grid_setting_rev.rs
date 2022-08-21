use crate::revision::{FieldRevision, FieldTypeRevision, FilterConfigurationRevision, GroupConfigurationRevision};
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt::Debug;
use std::sync::Arc;

pub fn gen_grid_filter_id() -> String {
    nanoid!(6)
}

pub fn gen_grid_group_id() -> String {
    nanoid!(6)
}

#[allow(dead_code)]
pub fn gen_grid_sort_id() -> String {
    nanoid!(6)
}

pub type FilterConfiguration = Configuration<FilterConfigurationRevision>;
pub type FilterConfigurationsByFieldId = HashMap<String, Vec<Arc<FilterConfigurationRevision>>>;
//
pub type GroupConfiguration = Configuration<GroupConfigurationRevision>;
pub type GroupConfigurationsByFieldId = HashMap<String, Vec<Arc<GroupConfigurationRevision>>>;

#[derive(Debug, Clone, Serialize, Deserialize, Default, Eq, PartialEq)]
#[serde(transparent)]
pub struct Configuration<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    /// Key:    field_id
    /// Value:  this value contains key/value.
    ///         Key: FieldType,
    ///         Value: the corresponding objects.
    #[serde(with = "indexmap::serde_seq")]
    inner: IndexMap<String, ObjectIndexMap<T>>,
}

impl<T> Configuration<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    pub fn get_mut_objects(&mut self, field_id: &str, field_type: &FieldTypeRevision) -> Option<&mut Vec<Arc<T>>> {
        let value = self
            .inner
            .get_mut(field_id)
            .and_then(|object_rev_map| object_rev_map.get_mut(field_type));
        if value.is_none() {
            tracing::warn!("[Configuration] Can't find the {:?} with", std::any::type_name::<T>());
        }
        value
    }
    pub fn get_objects(&self, field_id: &str, field_type_rev: &FieldTypeRevision) -> Option<Vec<Arc<T>>> {
        self.inner
            .get(field_id)
            .and_then(|object_rev_map| object_rev_map.get(field_type_rev))
            .cloned()
    }

    pub fn get_all_objects(&self, field_revs: &[Arc<FieldRevision>]) -> Option<HashMap<String, Vec<Arc<T>>>> {
        // Get the objects according to the FieldType, so we need iterate the field_revs.
        let objects_by_field_id = field_revs
            .iter()
            .flat_map(|field_rev| {
                let field_type = &field_rev.ty;
                let field_id = &field_rev.id;

                let object_rev_map = self.inner.get(field_id)?;
                let objects: Vec<Arc<T>> = object_rev_map.get(field_type)?.clone();
                Some((field_rev.id.clone(), objects))
            })
            .collect::<HashMap<String, Vec<Arc<T>>>>();
        Some(objects_by_field_id)
    }

    pub fn insert_object(&mut self, field_id: &str, field_type: &FieldTypeRevision, object: T) {
        let object_rev_map = self
            .inner
            .entry(field_id.to_string())
            .or_insert_with(ObjectIndexMap::<T>::new);

        object_rev_map
            .entry(field_type.to_owned())
            .or_insert_with(Vec::new)
            .push(Arc::new(object))
    }

    pub fn remove_all(&mut self) {
        self.inner.clear()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, Eq, PartialEq)]
#[serde(transparent)]
pub struct ObjectIndexMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    #[serde(with = "indexmap::serde_seq")]
    pub object_by_field_type: IndexMap<FieldTypeRevision, Vec<Arc<T>>>,
}

impl<T> ObjectIndexMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    pub fn new() -> Self {
        ObjectIndexMap::default()
    }
}

impl<T> std::ops::Deref for ObjectIndexMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    type Target = IndexMap<FieldTypeRevision, Vec<Arc<T>>>;

    fn deref(&self) -> &Self::Target {
        &self.object_by_field_type
    }
}

impl<T> std::ops::DerefMut for ObjectIndexMap<T>
where
    T: Debug + Clone + Default + Eq + PartialEq + serde::Serialize + serde::de::DeserializeOwned + 'static,
{
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.object_by_field_type
    }
}
