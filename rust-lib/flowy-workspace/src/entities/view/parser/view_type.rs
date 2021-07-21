use crate::{entities::view::ViewType, sql_tables::view::ViewTableType};

#[derive(Debug)]
pub struct ViewTypeCheck(pub ViewTableType);

impl ViewTypeCheck {
    pub fn parse(s: ViewType) -> Result<ViewTypeCheck, String> {
        match s {
            ViewType::Docs => Ok(Self(ViewTableType::Docs)),
        }
    }
}
