use collab_database::views::DatabaseLayout;
use flowy_database2::services::setting::CalendarLayoutSetting;

use crate::database::layout_test::script::DatabaseLayoutTest;
use crate::database::layout_test::script::LayoutScript::*;

#[tokio::test]
async fn calendar_initial_layout_setting_test() {
  let mut test = DatabaseLayoutTest::new_calendar().await;
  let date_field = test.get_first_date_field().await;
  let default_calendar_setting = CalendarLayoutSetting::new(date_field.id.clone());
  let scripts = vec![AssertCalendarLayoutSetting {
    expected: default_calendar_setting,
  }];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn calendar_get_events_test() {
  let mut test = DatabaseLayoutTest::new_calendar().await;
  let scripts = vec![AssertDefaultAllCalendarEvents];
  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn grid_to_calendar_layout_test() {
  let mut test = DatabaseLayoutTest::new_no_date_grid().await;
  let scripts = vec![
    UpdateDatabaseLayout {
      layout: DatabaseLayout::Calendar,
    },
    AssertAllCalendarEventsCount { expected: 3 },
  ];
  test.run_scripts(scripts).await;
}
