use lib_ot::{core::DeltaBuilder, rich_text::RichTextDelta};

#[inline]
pub fn initial_quill_delta() -> RichTextDelta {
    DeltaBuilder::new().insert("\n").build()
}

#[inline]
pub fn initial_quill_delta_string() -> String {
    initial_quill_delta().to_json_str()
}

#[inline]
pub fn initial_read_me() -> RichTextDelta {
    let json = include_str!("READ_ME.json");
    RichTextDelta::from_json_str(json).unwrap()
}

#[cfg(test)]
mod tests {
    use crate::client_document::default::initial_read_me;

    #[test]
    fn load_read_me() {
        println!("{}", initial_read_me().to_json_str());
    }
}
