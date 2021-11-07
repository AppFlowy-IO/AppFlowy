#[derive(Debug)]
pub struct AppColorStyle {
    pub theme_color: String,
}

impl AppColorStyle {
    pub fn parse(theme_color: String) -> Result<AppColorStyle, String> {
        // TODO: verify the color style format
        Ok(AppColorStyle { theme_color })
    }
}
