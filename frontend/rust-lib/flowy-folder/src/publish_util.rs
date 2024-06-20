use crate::entities::ViewPB;
use flowy_folder_pub::entities::PublishViewInfo;
use regex::Regex;

fn replace_invalid_url_chars(input: &str) -> String {
  let re = Regex::new(r"[^\w-]").unwrap();

  let replaced = re.replace_all(input, "_").to_string();
  if replaced.len() > 20 {
    replaced[..20].to_string()
  } else {
    replaced
  }
}
pub fn generate_publish_name(id: &str, name: &str) -> String {
  let name = replace_invalid_url_chars(name);
  format!("{}-{}", name, id)
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
