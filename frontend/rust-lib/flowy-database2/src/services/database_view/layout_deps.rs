use collab_database::database::{gen_field_id, Database};
use collab_database::fields::Field;
use collab_database::views::{
  DatabaseLayout, FieldSettingsByFieldIdMap, LayoutSetting, OrderObjectPosition,
};
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::entities::FieldType;
use crate::services::field::{DateTypeOption, SingleSelectTypeOption};
use crate::services::field_settings::default_field_settings_by_layout_map;
use crate::services::setting::{BoardLayoutSetting, CalendarLayoutSetting};

/// When creating a database, we need to resolve the dependencies of the views.
/// Different database views have different dependencies. For example, a board
/// view depends on a field that can be used to group rows while a calendar view
/// depends on a date field.
pub struct DatabaseLayoutDepsResolver {
  pub database: Arc<RwLock<Database>>,
  /// The new database layout.
  pub database_layout: DatabaseLayout,
}

impl DatabaseLayoutDepsResolver {
  pub fn new(database: Arc<RwLock<Database>>, database_layout: DatabaseLayout) -> Self {
    Self {
      database,
      database_layout,
    }
  }

  pub async fn resolve_deps_when_create_database_linked_view(
    &self,
    view_id: &str,
  ) -> (
    Option<Field>,
    Option<LayoutSetting>,
    Option<FieldSettingsByFieldIdMap>,
  ) {
    match self.database_layout {
      DatabaseLayout::Grid => (None, None, None),
      DatabaseLayout::Board => {
        let layout_settings = BoardLayoutSetting::new().into();

        let database = self.database.read().await;
        let field = if !database
          .get_fields(None)
          .into_iter()
          .any(|field| FieldType::from(field.field_type).can_be_group())
        {
          Some(self.create_select_field())
        } else {
          None
        };

        let field_settings_map = database.get_field_settings(view_id, None);
        tracing::info!(
          "resolve_deps_when_create_database_linked_view {:?}",
          field_settings_map
        );

        (
          field,
          Some(layout_settings),
          Some(field_settings_map.into()),
        )
      },
      DatabaseLayout::Calendar => {
        match self
          .database
          .read()
          .await
          .get_fields(None)
          .into_iter()
          .find(|field| FieldType::from(field.field_type) == FieldType::DateTime)
        {
          Some(field) => {
            let layout_setting = CalendarLayoutSetting::new(field.id).into();
            (None, Some(layout_setting), None)
          },
          None => {
            let date_field = self.create_date_field();
            let layout_setting = CalendarLayoutSetting::new(date_field.clone().id).into();
            (Some(date_field), Some(layout_setting), None)
          },
        }
      },
    }
  }

  /// If the new layout type is a calendar and there is not date field in the database, it will add
  /// a new date field to the database and create the corresponding layout setting.
  pub async fn resolve_deps_when_update_layout_type(&self, view_id: &str) {
    let mut database = self.database.write().await;
    let fields = database.get_fields(None);
    // Insert the layout setting if it's not exist
    match &self.database_layout {
      DatabaseLayout::Grid => {},
      DatabaseLayout::Board => {
        if database
          .get_layout_setting::<BoardLayoutSetting>(view_id, &self.database_layout)
          .is_none()
        {
          let layout_setting = BoardLayoutSetting::new();
          database.insert_layout_setting(view_id, &self.database_layout, layout_setting);
        }
      },
      DatabaseLayout::Calendar => {
        let date_field_id = match fields
          .into_iter()
          .find(|field| FieldType::from(field.field_type) == FieldType::DateTime)
        {
          None => {
            tracing::trace!("Create a new date field after layout type change");
            let field = self.create_date_field();
            let field_id = field.id.clone();
            database.create_field(
              None,
              field,
              &OrderObjectPosition::End,
              default_field_settings_by_layout_map(),
            );
            field_id
          },
          Some(date_field) => date_field.id,
        };
        if database
          .get_layout_setting::<CalendarLayoutSetting>(view_id, &self.database_layout)
          .is_none()
        {
          let layout_setting = CalendarLayoutSetting::new(date_field_id);
          database.insert_layout_setting(view_id, &self.database_layout, layout_setting);
        }
      },
    }
  }

  fn create_date_field(&self) -> Field {
    let field_type = FieldType::DateTime;
    let default_date_type_option = DateTypeOption::default();
    let field_id = gen_field_id();
    Field::new(field_id, "Date".to_string(), field_type.into(), false)
      .with_type_option_data(field_type, default_date_type_option.into())
  }

  fn create_select_field(&self) -> Field {
    let field_type = FieldType::SingleSelect;
    let default_select_type_option = SingleSelectTypeOption::default();
    let field_id = gen_field_id();
    Field::new(field_id, "Status".to_string(), field_type.into(), false)
      .with_type_option_data(field_type, default_select_type_option.into())
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
