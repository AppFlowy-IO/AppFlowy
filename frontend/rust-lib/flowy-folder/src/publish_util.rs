use crate::entities::ViewPB;
use flowy_folder_pub::entities::PublishViewInfo;
use regex::Regex;
use tracing::trace;

fn replace_invalid_url_chars(input: &str) -> String {
  let regex = Regex::new(r"[^\w-]").unwrap();
  regex.replace_all(input, "-").to_string()
}

pub fn generate_publish_name(id: &str, name: &str) -> String {
  let id_len = id.len();
  let name = replace_invalid_url_chars(name);
  let name_len = name.len();
  // The backend limits the publish name to a maximum of 50 characters.
  // If the combined length of the ID and the name exceeds 50 characters,
  // we will truncate the name to ensure the final result is within the limit.
  // The name should only contain alphanumeric characters and hyphens.
  let result = format!("{}-{}", &name[..std::cmp::min(49 - id_len, name_len)], id);
  trace!("generate_publish_name: {}", result);
  result
}

pub fn view_pb_to_publish_view(view: &ViewPB) -> PublishViewInfo {
  PublishViewInfo {
    view_id: view.id.clone(),
    name: view.name.clone(),
    layout: view.layout.clone().into(),
    icon: view.icon.clone().map(|icon| icon.into()),
    child_views: None,
    extra: view.extra.clone(),
    created_by: view.created_by,
    last_edited_by: view.last_edited_by,
    last_edited_time: view.last_edited,
    created_at: view.create_time,
  }
}
