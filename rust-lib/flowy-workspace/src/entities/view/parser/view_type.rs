use crate::{entities::view::ViewTypeIdentifier, sql_tables::view::ViewType};

#[derive(Debug)]
pub struct ViewTypeCheck(pub ViewType);

impl ViewTypeCheck {
    pub fn parse(s: ViewTypeIdentifier) -> Result<ViewTypeCheck, String> {
        match s {
            ViewTypeIdentifier::Docs => Ok(Self(ViewType::Docs)),
        }
    }
}
