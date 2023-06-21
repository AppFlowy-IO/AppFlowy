use std::sync::Arc;

use collab_database::database::{gen_field_id, Database};
use collab_database::fields::Field;
use collab_database::views::{DatabaseLayout, LayoutSetting};

use crate::entities::FieldType;
use crate::services::field::DateTypeOption;
use crate::services::setting::CalendarLayoutSetting;

/// When creating a database, we need to resolve the dependencies of the views. Different database
/// view has different dependencies. For example, a calendar view depends on a date field.
pub struct DatabaseLayoutDepsResolver {
  pub database: Arc<Database>,
  /// The new database layout.
  pub database_layout: DatabaseLayout,
}

impl DatabaseLayoutDepsResolver {
  pub fn new(database: Arc<Database>, database_layout: DatabaseLayout) -> Self {
    Self {
      database,
      database_layout,
    }
  }

  pub fn resolve_deps_when_create_database_linked_view(&self) -> Option<(Field, LayoutSetting)> {
    match self.database_layout {
      DatabaseLayout::Grid => None,
      DatabaseLayout::Board => None,
      DatabaseLayout::Calendar => {
        let field = self.create_date_field();
        let layout_setting: LayoutSetting = CalendarLayoutSetting::new(field.id.clone()).into();
        Some((field, layout_setting))
      },
    }
  }

  /// If the new layout type is a calendar and there is not date field in the database, it will add
  /// a new date field to the database and create the corresponding layout setting.
  pub fn resolve_deps_when_update_layout_type(&self, view_id: &str) {
    let fields = self.database.get_fields(None);
    // Insert the layout setting if it's not exist
    match &self.database_layout {
      DatabaseLayout::Grid => {},
      DatabaseLayout::Board => {},
      DatabaseLayout::Calendar => {
        let date_field_id = match fields
          .into_iter()
          .find(|field| FieldType::from(field.field_type) == FieldType::DateTime)
        {
          None => {
            tracing::trace!("Create a new date field after layout type change");
            let field = self.create_date_field();
            let field_id = field.id.clone();
            self.database.create_field(field);
            field_id
          },
          Some(date_field) => date_field.id,
        };
        self.create_calendar_layout_setting_if_need(view_id, &date_field_id);
      },
    }
  }

  fn create_calendar_layout_setting_if_need(&self, view_id: &str, field_id: &str) {
    if self
      .database
      .get_layout_setting::<CalendarLayoutSetting>(view_id, &self.database_layout)
      .is_none()
    {
      let layout_setting = CalendarLayoutSetting::new(field_id.to_string());
      self
        .database
        .insert_layout_setting(view_id, &self.database_layout, layout_setting);
    }
  }

  fn create_date_field(&self) -> Field {
    let field_type = FieldType::DateTime;
    let default_date_type_option = DateTypeOption::default();
    let field_id = gen_field_id();
    Field::new(
      field_id,
      "Date".to_string(),
      field_type.clone().into(),
      false,
    )
    .with_type_option_data(field_type, default_date_type_option.into())
  }
}

// pub async fn v_get_layout_settings(&self, layout_ty: &DatabaseLayout) -> LayoutSettingParams {
//   let mut layout_setting = LayoutSettingParams::default();
//   match layout_ty {
//     DatabaseLayout::Grid => {},
//     DatabaseLayout::Board => {},
//     DatabaseLayout::Calendar => {
//       if let Some(value) = self.delegate.get_layout_setting(&self.view_id, layout_ty) {
//         let calendar_setting = CalendarLayoutSetting::from(value);
//         // Check the field exist or not
//         if let Some(field) = self.delegate.get_field(&calendar_setting.field_id).await {
//           let field_type = FieldType::from(field.field_type);
//
//           // Check the type of field is Datetime or not
//           if field_type == FieldType::DateTime {
//             layout_setting.calendar = Some(calendar_setting);
//           }
//         }
//       }
//     },
//   }
//
//   layout_setting
// }
