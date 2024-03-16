use std::{
  fmt::{Display, Formatter},
  sync::Arc,
};

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use serde_repr::{Deserialize_repr, Serialize_repr};

use crate::{entities::FieldType, impl_into_calculation_type, services::calculations::Calculation};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CalculationPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3)]
  pub calculation_type: CalculationType,

  #[pb(index = 4)]
  pub value: String,
}

impl std::convert::From<&Calculation> for CalculationPB {
  fn from(calculation: &Calculation) -> Self {
    let calculation_type = calculation.calculation_type.into();

    Self {
      id: calculation.id.clone(),
      field_id: calculation.field_id.clone(),
      calculation_type,
      value: calculation.value.clone(),
    }
  }
}

impl std::convert::From<&Arc<Calculation>> for CalculationPB {
  fn from(calculation: &Arc<Calculation>) -> Self {
    let calculation_type = calculation.calculation_type.into();

    Self {
      id: calculation.id.clone(),
      field_id: calculation.field_id.clone(),
      calculation_type,
      value: calculation.value.clone(),
    }
  }
}

#[derive(
  Default, Debug, Copy, Clone, PartialEq, Hash, Eq, ProtoBuf_Enum, Serialize_repr, Deserialize_repr,
)]
#[repr(u8)]
pub enum CalculationType {
  #[default]
  Average = 0, // Number
  Max = 1,           // Number
  Median = 2,        // Number
  Min = 3,           // Number
  Sum = 4,           // Number
  Count = 5,         // All
  CountEmpty = 6,    // All
  CountNonEmpty = 7, // All
}

impl Display for CalculationType {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    let value: i64 = (*self).into();
    f.write_fmt(format_args!("{}", value))
  }
}

impl AsRef<CalculationType> for CalculationType {
  fn as_ref(&self) -> &CalculationType {
    self
  }
}

impl From<&CalculationType> for CalculationType {
  fn from(calculation_type: &CalculationType) -> Self {
    *calculation_type
  }
}

impl CalculationType {
  pub fn value(&self) -> i64 {
    (*self).into()
  }
}

impl_into_calculation_type!(i64);
impl_into_calculation_type!(u8);

impl From<CalculationType> for i64 {
  fn from(ty: CalculationType) -> Self {
    (ty as u8) as i64
  }
}

impl From<&CalculationType> for i64 {
  fn from(ty: &CalculationType) -> Self {
    i64::from(*ty)
  }
}

impl CalculationType {
  pub fn is_allowed(&self, field_type: FieldType) -> bool {
    match self {
      // Number fields only
      CalculationType::Max
      | CalculationType::Min
      | CalculationType::Average
      | CalculationType::Median
      | CalculationType::Sum => {
        matches!(field_type, FieldType::Number)
      },
      // Exclude some fields from CountNotEmpty & CountEmpty
      CalculationType::CountEmpty | CalculationType::CountNonEmpty => !matches!(
        field_type,
        FieldType::URL | FieldType::Checkbox | FieldType::CreatedTime | FieldType::LastEditedTime
      ),
      // All fields
      CalculationType::Count => true,
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedCalculationsPB {
  #[pb(index = 1)]
  pub items: Vec<CalculationPB>,
}

impl std::convert::From<Vec<Arc<Calculation>>> for RepeatedCalculationsPB {
  fn from(calculations: Vec<Arc<Calculation>>) -> Self {
    RepeatedCalculationsPB {
      items: calculations
        .into_iter()
        .map(|rev: Arc<Calculation>| rev.as_ref().into())
        .collect(),
    }
  }
}

impl std::convert::From<Vec<CalculationPB>> for RepeatedCalculationsPB {
  fn from(items: Vec<CalculationPB>) -> Self {
    Self { items }
  }
}
