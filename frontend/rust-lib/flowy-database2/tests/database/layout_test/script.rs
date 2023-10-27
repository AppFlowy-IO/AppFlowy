use collab_database::fields::Field;
use collab_database::views::DatabaseLayout;

use flowy_database2::entities::{FieldType, LayoutSettingChangeset, LayoutSettingParams};
use flowy_database2::services::setting::{BoardLayoutSetting, CalendarLayoutSetting};

use crate::database::database_editor::DatabaseEditorTest;

pub enum LayoutScript {
  AssertBoardLayoutSetting { expected: BoardLayoutSetting },
  AssertCalendarLayoutSetting { expected: CalendarLayoutSetting },
  UpdateBoardLayoutSetting { new_setting: BoardLayoutSetting },
  AssertDefaultAllCalendarEvents,
  AssertAllCalendarEventsCount { expected: usize },
  UpdateDatabaseLayout { layout: DatabaseLayout },
}

pub struct DatabaseLayoutTest {
  database_test: DatabaseEditorTest,
}

impl DatabaseLayoutTest {
  pub async fn new_no_date_grid() -> Self {
    let database_test = DatabaseEditorTest::new_no_date_grid().await;
    Self { database_test }
  }

  pub async fn new_board() -> Self {
    let database_test = DatabaseEditorTest::new_board().await;
    Self { database_test }
  }

  pub async fn new_calendar() -> Self {
    let database_test = DatabaseEditorTest::new_calendar().await;
    Self { database_test }
  }

  pub async fn get_first_date_field(&self) -> Field {
    self.database_test.get_first_field(FieldType::DateTime)
  }

  async fn get_layout_setting(
    &self,
    view_id: &str,
    layout_ty: DatabaseLayout,
  ) -> LayoutSettingParams {
    self
      .database_test
      .editor
      .get_layout_setting(view_id, layout_ty)
      .await
      .unwrap()
  }

  pub async fn run_scripts(&mut self, scripts: Vec<LayoutScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: LayoutScript) {
    match script {
      LayoutScript::UpdateDatabaseLayout { layout } => {
        self
          .database_test
          .editor
          .update_view_layout(&self.database_test.view_id, layout)
          .await
          .unwrap();
      },
      LayoutScript::AssertAllCalendarEventsCount { expected } => {
        let events = self
          .database_test
          .editor
          .get_all_calendar_events(&self.database_test.view_id)
          .await;
        assert_eq!(events.len(), expected);
      },
      LayoutScript::AssertBoardLayoutSetting { expected } => {
        let view_id = self.database_test.view_id.clone();
        let layout_ty = DatabaseLayout::Board;

        let layout_settings = self.get_layout_setting(&view_id, layout_ty).await;

        assert!(layout_settings.calendar.is_none());
        assert_eq!(
          layout_settings.board.unwrap().hide_ungrouped_column,
          expected.hide_ungrouped_column
        );
      },
      LayoutScript::AssertCalendarLayoutSetting { expected } => {
        let view_id = self.database_test.view_id.clone();
        let layout_ty = DatabaseLayout::Calendar;

        let layout_settings = self.get_layout_setting(&view_id, layout_ty).await;

        assert!(layout_settings.board.is_none());

        let calendar_setting = layout_settings.calendar.unwrap();
        assert_eq!(calendar_setting.layout_ty, expected.layout_ty);
        assert_eq!(
          calendar_setting.first_day_of_week,
          expected.first_day_of_week
        );
        assert_eq!(calendar_setting.show_weekends, expected.show_weekends);
      },
      LayoutScript::UpdateBoardLayoutSetting { new_setting } => {
        let changeset = LayoutSettingChangeset {
          view_id: self.database_test.view_id.clone(),
          layout_type: DatabaseLayout::Board,
          board: Some(new_setting),
          calendar: None,
        };
        self
          .database_test
          .editor
          .set_layout_setting(&self.database_test.view_id, changeset)
          .await
          .unwrap()
      },
      LayoutScript::AssertDefaultAllCalendarEvents => {
        let events = self
          .database_test
          .editor
          .get_all_calendar_events(&self.database_test.view_id)
          .await;
        assert_eq!(events.len(), 5);

        for (index, event) in events.into_iter().enumerate() {
          if index == 0 {
            assert_eq!(event.title, "A");
            assert_eq!(event.timestamp, 1678090778);
          }

          if index == 1 {
            assert_eq!(event.title, "B");
            assert_eq!(event.timestamp, 1677917978);
          }
          if index == 2 {
            assert_eq!(event.title, "C");
            assert_eq!(event.timestamp, 1679213978);
          }
          if index == 4 {
            assert_eq!(event.title, "E");
            assert_eq!(event.timestamp, 1678695578);
          }
        }
      },
    }
  }
}
