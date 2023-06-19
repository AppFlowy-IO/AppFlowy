use collab_database::fields::Field;
use collab_database::views::DatabaseLayout;

use flowy_database2::entities::FieldType;
use flowy_database2::services::setting::CalendarLayoutSetting;

use crate::database::database_editor::DatabaseEditorTest;

pub enum LayoutScript {
  AssertCalendarLayoutSetting { expected: CalendarLayoutSetting },
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

  pub async fn new_calendar() -> Self {
    let database_test = DatabaseEditorTest::new_calendar().await;
    Self { database_test }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<LayoutScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn get_first_date_field(&self) -> Field {
    self.database_test.get_first_field(FieldType::DateTime)
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
      LayoutScript::AssertCalendarLayoutSetting { expected } => {
        let view_id = self.database_test.view_id.clone();
        let layout_ty = DatabaseLayout::Calendar;

        let calendar_setting = self
          .database_test
          .editor
          .get_layout_setting(&view_id, layout_ty)
          .await
          .unwrap()
          .calendar
          .unwrap();

        assert_eq!(calendar_setting.layout_ty, expected.layout_ty);
        assert_eq!(
          calendar_setting.first_day_of_week,
          expected.first_day_of_week
        );
        assert_eq!(calendar_setting.show_weekends, expected.show_weekends);
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
