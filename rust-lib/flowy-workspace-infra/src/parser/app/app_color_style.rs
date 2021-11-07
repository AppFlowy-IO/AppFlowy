use crate::errors::ErrorCode;

#[derive(Debug)]
pub struct AppColorStyle {
    pub theme_color: String,
}

impl AppColorStyle {
    pub fn parse(theme_color: String) -> Result<AppColorStyle, ErrorCode> {
        // TODO: verify the color style format
        Ok(AppColorStyle { theme_color })
    }
}
