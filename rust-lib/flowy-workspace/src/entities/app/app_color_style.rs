use crate::entities::app::ColorStyle;

#[derive(Debug)]
pub struct AppColorStyle(pub ColorStyle);

impl AppColorStyle {
    pub fn parse(color_style: ColorStyle) -> Result<AppColorStyle, String> {
        // TODO: verify the color style format
        Ok(Self(color_style))
    }
}

impl AsRef<ColorStyle> for AppColorStyle {
    fn as_ref(&self) -> &ColorStyle { &self.0 }
}
