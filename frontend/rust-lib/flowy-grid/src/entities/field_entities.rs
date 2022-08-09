use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::{FieldRevision, FieldTypeRevision};
use flowy_sync::entities::grid::FieldChangesetParams;
use serde_repr::*;
use std::sync::Arc;

use strum_macros::{Display, EnumCount as EnumCountMacro, EnumIter, EnumString};

/// [GridFieldPB] defines a Field's attributes. Such as the name, field_type, and width. etc.
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridFieldPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub field_type: FieldType,

    #[pb(index = 5)]
    pub frozen: bool,

    #[pb(index = 6)]
    pub visibility: bool,

    #[pb(index = 7)]
    pub width: i32,

    #[pb(index = 8)]
    pub is_primary: bool,
}

impl std::convert::From<FieldRevision> for GridFieldPB {
    fn from(field_rev: FieldRevision) -> Self {
        Self {
            id: field_rev.id,
            name: field_rev.name,
            desc: field_rev.desc,
            field_type: field_rev.field_type_rev.into(),
            frozen: field_rev.frozen,
            visibility: field_rev.visibility,
            width: field_rev.width,
            is_primary: field_rev.is_primary,
        }
    }
}

impl std::convert::From<Arc<FieldRevision>> for GridFieldPB {
    fn from(field_rev: Arc<FieldRevision>) -> Self {
        let field_rev = field_rev.as_ref().clone();
        GridFieldPB::from(field_rev)
    }
}

/// [GridFieldIdPB] id of the [Field]
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridFieldIdPB {
    #[pb(index = 1)]
    pub field_id: String,
}

impl std::convert::From<&str> for GridFieldIdPB {
    fn from(s: &str) -> Self {
        GridFieldIdPB { field_id: s.to_owned() }
    }
}

impl std::convert::From<String> for GridFieldIdPB {
    fn from(s: String) -> Self {
        GridFieldIdPB { field_id: s }
    }
}

impl std::convert::From<&Arc<FieldRevision>> for GridFieldIdPB {
    fn from(field_rev: &Arc<FieldRevision>) -> Self {
        Self {
            field_id: field_rev.id.clone(),
        }
    }
}
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridFieldChangesetPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub inserted_fields: Vec<IndexFieldPB>,

    #[pb(index = 3)]
    pub deleted_fields: Vec<GridFieldIdPB>,

    #[pb(index = 4)]
    pub updated_fields: Vec<GridFieldPB>,
}

impl GridFieldChangesetPB {
    pub fn insert(grid_id: &str, inserted_fields: Vec<IndexFieldPB>) -> Self {
        Self {
            grid_id: grid_id.to_owned(),
            inserted_fields,
            deleted_fields: vec![],
            updated_fields: vec![],
        }
    }

    pub fn delete(grid_id: &str, deleted_fields: Vec<GridFieldIdPB>) -> Self {
        Self {
            grid_id: grid_id.to_string(),
            inserted_fields: vec![],
            deleted_fields,
            updated_fields: vec![],
        }
    }

    pub fn update(grid_id: &str, updated_fields: Vec<GridFieldPB>) -> Self {
        Self {
            grid_id: grid_id.to_string(),
            inserted_fields: vec![],
            deleted_fields: vec![],
            updated_fields,
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct IndexFieldPB {
    #[pb(index = 1)]
    pub field: GridFieldPB,

    #[pb(index = 2)]
    pub index: i32,
}

impl IndexFieldPB {
    pub fn from_field_rev(field_rev: &Arc<FieldRevision>, index: usize) -> Self {
        Self {
            field: GridFieldPB::from(field_rev.as_ref().clone()),
            index: index as i32,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GetEditFieldContextPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2, one_of)]
    pub field_id: Option<String>,

    #[pb(index = 3)]
    pub field_type: FieldType,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct CreateFieldPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,
}

pub struct CreateFieldParams {
    pub grid_id: String,
    pub field_type: FieldType,
}

impl TryInto<CreateFieldParams> for CreateFieldPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateFieldParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(CreateFieldParams {
            grid_id: grid_id.0,
            field_type: self.field_type,
        })
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct EditFieldPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,

    #[pb(index = 4)]
    pub create_if_not_exist: bool,
}

pub struct EditFieldParams {
    pub grid_id: String,
    pub field_id: String,
    pub field_type: FieldType,
}

impl TryInto<EditFieldParams> for EditFieldPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<EditFieldParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(EditFieldParams {
            grid_id: grid_id.0,
            field_id: field_id.0,
            field_type: self.field_type,
        })
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridFieldTypeOptionIdPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,
}

pub struct GridFieldTypeOptionIdParams {
    pub grid_id: String,
    pub field_id: String,
    pub field_type: FieldType,
}

impl TryInto<GridFieldTypeOptionIdParams> for GridFieldTypeOptionIdPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridFieldTypeOptionIdParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(GridFieldTypeOptionIdParams {
            grid_id: grid_id.0,
            field_id: field_id.0,
            field_type: self.field_type,
        })
    }
}

/// Certain field types have user-defined options such as color, date format, number format,
/// or a list of values for a multi-select list. These options are defined within a specialization
/// of the FieldTypeOption class.
///
/// You could check [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid#fieldtype)
/// for more information.
///
#[derive(Debug, Default, ProtoBuf)]
pub struct FieldTypeOptionDataPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field: GridFieldPB,

    #[pb(index = 3)]
    pub type_option_data: Vec<u8>,
}

/// Collection of the [GridFieldPB]
#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedGridFieldPB {
    #[pb(index = 1)]
    pub items: Vec<GridFieldPB>,
}
impl std::ops::Deref for RepeatedGridFieldPB {
    type Target = Vec<GridFieldPB>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedGridFieldPB {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl std::convert::From<Vec<GridFieldPB>> for RepeatedGridFieldPB {
    fn from(items: Vec<GridFieldPB>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedGridFieldIdPB {
    #[pb(index = 1)]
    pub items: Vec<GridFieldIdPB>,
}

impl std::ops::Deref for RepeatedGridFieldIdPB {
    type Target = Vec<GridFieldIdPB>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::convert::From<Vec<GridFieldIdPB>> for RepeatedGridFieldIdPB {
    fn from(items: Vec<GridFieldIdPB>) -> Self {
        RepeatedGridFieldIdPB { items }
    }
}

impl std::convert::From<String> for RepeatedGridFieldIdPB {
    fn from(s: String) -> Self {
        RepeatedGridFieldIdPB {
            items: vec![GridFieldIdPB::from(s)],
        }
    }
}

#[derive(ProtoBuf, Default)]
pub struct InsertFieldPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field: GridFieldPB,

    #[pb(index = 3)]
    pub type_option_data: Vec<u8>,

    #[pb(index = 4, one_of)]
    pub start_field_id: Option<String>,
}

#[derive(Clone)]
pub struct InsertFieldParams {
    pub grid_id: String,
    pub field: GridFieldPB,
    pub type_option_data: Vec<u8>,
    pub start_field_id: Option<String>,
}

impl TryInto<InsertFieldParams> for InsertFieldPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<InsertFieldParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let _ = NotEmptyStr::parse(self.field.id.clone()).map_err(|_| ErrorCode::FieldIdIsEmpty)?;

        let start_field_id = match self.start_field_id {
            None => None,
            Some(id) => Some(NotEmptyStr::parse(id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(InsertFieldParams {
            grid_id: grid_id.0,
            field: self.field,
            type_option_data: self.type_option_data,
            start_field_id,
        })
    }
}

/// [UpdateFieldTypeOptionPayloadPB] is used to update the type option data.
#[derive(ProtoBuf, Default)]
pub struct UpdateFieldTypeOptionPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    /// Check out [FieldTypeOptionDataPB] for more details.
    #[pb(index = 3)]
    pub type_option_data: Vec<u8>,
}

#[derive(Clone)]
pub struct UpdateFieldTypeOptionParams {
    pub grid_id: String,
    pub field_id: String,
    pub type_option_data: Vec<u8>,
}

impl TryInto<UpdateFieldTypeOptionParams> for UpdateFieldTypeOptionPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<UpdateFieldTypeOptionParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let _ = NotEmptyStr::parse(self.field_id.clone()).map_err(|_| ErrorCode::FieldIdIsEmpty)?;

        Ok(UpdateFieldTypeOptionParams {
            grid_id: grid_id.0,
            field_id: self.field_id,
            type_option_data: self.type_option_data,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct QueryFieldPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_ids: RepeatedGridFieldIdPB,
}

pub struct QueryFieldParams {
    pub grid_id: String,
    pub field_ids: RepeatedGridFieldIdPB,
}

impl TryInto<QueryFieldParams> for QueryFieldPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryFieldParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryFieldParams {
            grid_id: grid_id.0,
            field_ids: self.field_ids,
        })
    }
}

/// [FieldChangesetPayloadPB] is used to modify the corresponding field. It defines which properties of
/// the field can be modified.
///
/// Pass in None if you don't want to modify a property
/// Pass in Some(Value) if you want to modify a property
///
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldChangesetPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3, one_of)]
    pub name: Option<String>,

    #[pb(index = 4, one_of)]
    pub desc: Option<String>,

    #[pb(index = 5, one_of)]
    pub field_type: Option<FieldType>,

    #[pb(index = 6, one_of)]
    pub frozen: Option<bool>,

    #[pb(index = 7, one_of)]
    pub visibility: Option<bool>,

    #[pb(index = 8, one_of)]
    pub width: Option<i32>,

    #[pb(index = 9, one_of)]
    pub type_option_data: Option<Vec<u8>>,
}

impl TryInto<FieldChangesetParams> for FieldChangesetPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<FieldChangesetParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        let field_type = self.field_type.map(FieldTypeRevision::from);
        if let Some(type_option_data) = self.type_option_data.as_ref() {
            if type_option_data.is_empty() {
                return Err(ErrorCode::TypeOptionDataIsEmpty);
            }
        }

        Ok(FieldChangesetParams {
            field_id: field_id.0,
            grid_id: grid_id.0,
            name: self.name,
            desc: self.desc,
            field_type,
            frozen: self.frozen,
            visibility: self.visibility,
            width: self.width,
            type_option_data: self.type_option_data,
        })
    }
}

#[derive(
    Debug,
    Clone,
    PartialEq,
    Hash,
    Eq,
    ProtoBuf_Enum,
    EnumCountMacro,
    EnumString,
    EnumIter,
    Display,
    Serialize_repr,
    Deserialize_repr,
)]
/// The order of the enum can't be changed. If you want to add a new type,
/// it would be better to append it to the end of the list.
#[repr(u8)]
pub enum FieldType {
    RichText = 0,
    Number = 1,
    DateTime = 2,
    SingleSelect = 3,
    MultiSelect = 4,
    Checkbox = 5,
    URL = 6,
}

impl std::default::Default for FieldType {
    fn default() -> Self {
        FieldType::RichText
    }
}

impl AsRef<FieldType> for FieldType {
    fn as_ref(&self) -> &FieldType {
        self
    }
}

impl From<&FieldType> for FieldType {
    fn from(field_type: &FieldType) -> Self {
        field_type.clone()
    }
}

impl FieldType {
    pub fn type_id(&self) -> String {
        (self.clone() as u8).to_string()
    }

    pub fn default_cell_width(&self) -> i32 {
        match self {
            FieldType::DateTime => 180,
            _ => 150,
        }
    }

    pub fn is_number(&self) -> bool {
        self == &FieldType::Number
    }

    pub fn is_text(&self) -> bool {
        self == &FieldType::RichText
    }

    pub fn is_checkbox(&self) -> bool {
        self == &FieldType::Checkbox
    }

    pub fn is_date(&self) -> bool {
        self == &FieldType::DateTime
    }

    pub fn is_single_select(&self) -> bool {
        self == &FieldType::SingleSelect
    }

    pub fn is_multi_select(&self) -> bool {
        self == &FieldType::MultiSelect
    }

    pub fn is_url(&self) -> bool {
        self == &FieldType::URL
    }

    pub fn is_select_option(&self) -> bool {
        self == &FieldType::MultiSelect || self == &FieldType::SingleSelect
    }
}

impl std::convert::From<&FieldType> for FieldTypeRevision {
    fn from(ty: &FieldType) -> Self {
        ty.clone() as u8
    }
}

impl std::convert::From<FieldType> for FieldTypeRevision {
    fn from(ty: FieldType) -> Self {
        ty as u8
    }
}

impl std::convert::From<&FieldTypeRevision> for FieldType {
    fn from(ty: &FieldTypeRevision) -> Self {
        FieldType::from(*ty)
    }
}
impl std::convert::From<FieldTypeRevision> for FieldType {
    fn from(ty: FieldTypeRevision) -> Self {
        match ty {
            0 => FieldType::RichText,
            1 => FieldType::Number,
            2 => FieldType::DateTime,
            3 => FieldType::SingleSelect,
            4 => FieldType::MultiSelect,
            5 => FieldType::Checkbox,
            6 => FieldType::URL,
            _ => {
                tracing::error!("Can't parser FieldTypeRevision: {} to FieldType", ty);
                FieldType::RichText
            }
        }
    }
}
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DuplicateFieldPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridFieldIdentifierPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,
}

impl TryInto<GridFieldIdParams> for DuplicateFieldPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridFieldIdParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(GridFieldIdParams {
            grid_id: grid_id.0,
            field_id: field_id.0,
        })
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DeleteFieldPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,
}

impl TryInto<GridFieldIdParams> for DeleteFieldPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridFieldIdParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(GridFieldIdParams {
            grid_id: grid_id.0,
            field_id: field_id.0,
        })
    }
}

pub struct GridFieldIdParams {
    pub field_id: String,
    pub grid_id: String,
}
