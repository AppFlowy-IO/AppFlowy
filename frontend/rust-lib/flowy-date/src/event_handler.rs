use chrono::{Datelike, NaiveDate};
use date_time_parser::DateParser;
use fancy_regex::Regex;
use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, DataResult};

use crate::entities::*;

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn query_date_handler(
  data: AFPluginData<DateQueryPB>,
) -> DataResult<DateResultPB, FlowyError> {
  let query: String = data.into_inner().query;
  let date = DateParser::parse(&query);

  let formatted: String;
  if date.is_some() {
    let naive_date = date.unwrap();

    let year_regex = Regex::new(r"\b\d{4}\b").unwrap();
    let year_match = year_regex.captures(&query).unwrap();

    if year_match.is_some() {
      let capture = year_match.unwrap().get(0).unwrap().as_str();
      let year = capture.parse::<i32>().unwrap();

      formatted = NaiveDate::from_ymd_opt(year, naive_date.month(), naive_date.day())
        .unwrap()
        .to_string();
    } else {
      formatted = naive_date.to_string();
    }
  } else {
    formatted = String::from("-1");
  }

  data_result_ok(DateResultPB { date: formatted })
}
