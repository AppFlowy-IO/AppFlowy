use lib_ot::{core::OperationBuilder, text_delta::TextDelta};

#[inline]
pub fn initial_quill_delta() -> TextDelta {
    OperationBuilder::new().insert("\n").build()
}

#[inline]
pub fn initial_quill_delta_string() -> String {
    initial_quill_delta().json_str()
}

#[inline]
pub fn initial_read_me() -> TextDelta {
    let json = include_str!("READ_ME.json");
    TextDelta::from_json(json).unwrap()
}

#[cfg(test)]
mod tests {
    use crate::client_document::default::initial_read_me;

    #[test]
    fn load_read_me() {
        println!("{}", initial_read_me().json_str());
    }
}
