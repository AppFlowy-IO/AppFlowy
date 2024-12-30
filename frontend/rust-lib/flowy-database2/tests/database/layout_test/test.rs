use crate::database::layout_test::script::DatabaseLayoutTest;
use collab_database::views::DatabaseLayout;
use flowy_database2::services::setting::{BoardLayoutSetting, CalendarLayoutSetting};

#[tokio::test]
async fn board_layout_setting_test() {
  let mut test = DatabaseLayoutTest::new_board().await;
  let default_board_setting = BoardLayoutSetting::new();
  let new_board_setting = BoardLayoutSetting {
    hide_ungrouped_column: true,
    ..default_board_setting
  };

  // Assert the initial default board layout setting
  test
    .assert_board_layout_setting(default_board_setting)
    .await;

  // Update the board layout setting and assert the changes
  test
    .update_board_layout_setting(new_board_setting.clone())
    .await;
  test.assert_board_layout_setting(new_board_setting).await;
}

#[tokio::test]
async fn calendar_initial_layout_setting_test() {
  let test = DatabaseLayoutTest::new_calendar().await;
  let date_field = test.get_first_date_field().await;
  let default_calendar_setting = CalendarLayoutSetting::new(date_field.id.clone());

  // Assert the initial calendar layout setting
  test
    .assert_calendar_layout_setting(default_calendar_setting)
    .await;
}

#[tokio::test]
async fn calendar_get_events_test() {
  let test = DatabaseLayoutTest::new_calendar().await;

  // Assert the default calendar events
  test.assert_default_all_calendar_events().await;
}

#[tokio::test]
async fn grid_to_calendar_layout_test() {
  let mut test = DatabaseLayoutTest::new_no_date_grid().await;

  // Update layout to calendar and assert the number of calendar events
  test.update_database_layout(DatabaseLayout::Calendar).await;
  test.assert_all_calendar_events_count(3).await;
}
