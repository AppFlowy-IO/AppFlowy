use crate::proto_gen::ast::FlowyEnum;
use crate::proto_gen::template::get_tera;
use tera::Context;

pub struct EnumTemplate {
    context: Context,
    items: Vec<String>,
}

#[allow(dead_code)]
impl EnumTemplate {
    pub fn new() -> Self {
        EnumTemplate {
            context: Context::new(),
            items: vec![],
        }
    }

    pub fn set_message_enum(&mut self, flowy_enum: &FlowyEnum) {
        self.context.insert("enum_name", &flowy_enum.name);
        flowy_enum.attrs.iter().for_each(|item| {
            self.items
                .push(format!("{} = {};", item.attrs.enum_item_name, item.attrs.value))
        })
    }

    pub fn render(&mut self) -> Option<String> {
        self.context.insert("items", &self.items);
        let tera = get_tera("proto_file");
        match tera.render("enum.tera", &self.context) {
            Ok(r) => Some(r),
            Err(e) => {
                log::error!("{:?}", e);
                None
            }
        }
    }
}
