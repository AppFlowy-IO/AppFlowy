use crate::{entities::view::ViewType, sql_tables::view::ViewTableType};

#[derive(Debug)]
pub struct ViewTypeCheck(pub ViewTableType);

impl ViewTypeCheck {
    pub fn parse(s: ViewType) -> Result<ViewTypeCheck, String> {
        match s {
            ViewType::Blank => {
                Err("Impossible to here, because you can create blank view".to_owned())
            },
            ViewType::Doc => Ok(Self(ViewTableType::Docs)),
        }
    }
}
