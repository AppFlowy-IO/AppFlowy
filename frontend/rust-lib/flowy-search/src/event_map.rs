use std::sync::Weak;
use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::{event_handler::search_handler, services::manager::SearchManager};

pub fn init(search_manager: Weak<SearchManager>) -> AFPlugin {
  AFPlugin::new()
    .state(search_manager)
    .name(env!("CARGO_PKG_NAME"))
    .event(SearchEvent::Search, search_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum SearchEvent {
  #[event(input = "SearchQueryPB")]
  Search = 0,
}
