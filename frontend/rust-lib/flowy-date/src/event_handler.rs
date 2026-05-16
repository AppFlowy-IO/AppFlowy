use chrono::{Datelike, NaiveDate};
use date_time_parser::DateParser;
use fancy_regex::Regex;
use flowy_error::FlowyError;
use lib_dispatch::prelude::{AFPluginData, DataResult, data_result_ok};
use std::sync::OnceLock;

use crate::entities::*;

static YEAR_REGEX: OnceLock<Regex> = OnceLock::new();

fn year_regex() -> &'static Regex {
  YEAR_REGEX.get_or_init(|| Regex::new(r"\b\d{4}\b").unwrap())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn query_date_handler(
  data: AFPluginData<DateQueryPB>,
) -> DataResult<DateResultPB, FlowyError> {
  let query: String = data.into_inner().query;
  let date = DateParser::parse(&query);

  match date {
    Some(naive_date) => {
      let year_match = year_regex().find(&query).unwrap();
      let formatted = year_match
        .and_then(|capture| capture.as_str().parse::<i32>().ok())
        .and_then(|year| NaiveDate::from_ymd_opt(year, naive_date.month0(), naive_date.day0()))
        .map(|date| date.to_string())
        .unwrap_or_else(|| naive_date.to_string());

      data_result_ok(DateResultPB { date: formatted })
    },
    None => Err(FlowyError::internal().with_context("Failed to parse date from")),
  }
}
