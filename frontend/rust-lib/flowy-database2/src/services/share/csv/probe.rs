use flowy_store::entities::*;
use std::convert::From;

pub fn update_field_from_cells(field: &Field, cells: &Vec<String>) -> Field {
  let mut mfield = field.clone();
  mfield.field_type = probe_field_type_from_cells(cells);
  mfield.type_options = probe_field_type_options(&mfield, cells);
  mfield
}

fn probe_field_type_from_cells(cells: &Vec<String>) -> FieldType {
  let mut field_type = FieldType::RichText;
  for cell in cells {
    let probe_type = FieldType::from(cell as &str);
    if probe_type != field_type {
      field_type = probe_type;
    } else {
      break;
    }
  }
  field_type
}

fn probe_field_type_options(field: &Field, cells: &Vec<String>) -> AnyData {
  match field.field_type {
    FieldType::RichText => probe_rich_text_description(field, cells),
    FieldType::Number => probe_number_description(field, cells),
    FieldType::DateTime => probe_date_description(field, cells),
    FieldType::SingleSelect => probe_single_select_description(field, cells),
    FieldType::MultiSelect => probe_multi_select_description(field, cells),
    FieldType::Checkbox => probe_checkbox_description(field, cells),
    FieldType::Attachment => probe_attachment_description(field, cells),
    FieldType::Document => probe_document_description(field, cells),
    FieldType::Relation => probe_relation_description(field, cells),
    FieldType::Lookup => probe_lookup_description(field, cells),
    FieldType::CheckList => probe_check_list_description(field, cells),
  }
}

#[allow(unused_variables)]
pub fn probe_rich_text_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let rich_text = RichTextDescription::default();
  rich_text.into()
}

#[allow(unused_variables)]
pub fn probe_number_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let mut number = NumberDescription::default();
  for cell in cells.iter().filter(|c| !c.is_empty()) {
    match string_to_money(cell) {
      Some(m) => {
        number = m.into();
        break;
      },
      None => {},
    }

    match cell.parse::<i64>() {
      Ok(v) => {
        number = v.into();
        break;
      },
      Err(_) => {},
    }
  }
  number.into()
}

#[allow(unused_variables)]
pub fn probe_date_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let date = DateDescription::default();
  date.into()
}

#[allow(unused_variables)]
pub fn probe_single_select_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let single_select = SingleSelectEntity::default();

  single_select.into()
}

#[allow(unused_variables)]
pub fn probe_multi_select_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let multi_select = MultiSelectEntity::default();
  multi_select.into()
}

#[allow(unused_variables)]
pub fn probe_attachment_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let attachment = AttachmentDescription::default();
  attachment.into()
}

#[allow(unused_variables)]
pub fn probe_checkbox_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let checkbox = CheckboxDescription::default();
  checkbox.into()
}

#[allow(unused_variables)]
pub fn probe_document_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let document = DocumentDescription::default();
  document.into()
}

#[allow(unused_variables)]
pub fn probe_relation_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let relation = RelationDescription::default();
  relation.into()
}

#[allow(unused_variables)]
pub fn probe_lookup_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let relation = LookupDescription::default();
  relation.into()
}

#[allow(unused_variables)]
pub fn probe_check_list_description(field: &Field, cells: &Vec<String>) -> AnyData {
  let check_list = CheckListDescription::default();
  check_list.into()
}
