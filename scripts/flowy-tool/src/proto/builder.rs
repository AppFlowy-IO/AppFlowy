use crate::proto::ProtoGen;

pub struct ProtoGenBuilder {
    rust_source_dir: Option<String>,
    proto_file_output_dir: Option<String>,
    rust_mod_dir: Option<String>,
    flutter_mod_dir: Option<String>,
    derive_meta_dir: Option<String>,
}

impl ProtoGenBuilder {
    pub fn new() -> Self {
        ProtoGenBuilder {
            rust_source_dir: None,
            proto_file_output_dir: None,
            rust_mod_dir: None,
            flutter_mod_dir: None,
            derive_meta_dir: None,
        }
    }

    pub fn set_rust_source_dir(mut self, dir: &str) -> Self {
        self.rust_source_dir = Some(dir.to_string());
        self
    }

    pub fn set_proto_file_output_dir(mut self, dir: &str) -> Self {
        self.proto_file_output_dir = Some(dir.to_string());
        self
    }

    pub fn set_rust_mod_dir(mut self, dir: &str) -> Self {
        self.rust_mod_dir = Some(dir.to_string());
        self
    }

    pub fn set_flutter_mod_dir(mut self, dir: &str) -> Self {
        self.flutter_mod_dir = Some(dir.to_string());
        self
    }

    pub fn set_derive_meta_dir(mut self, dir: &str) -> Self {
        self.derive_meta_dir = Some(dir.to_string());
        self
    }

    pub fn build(self) -> ProtoGen {
        ProtoGen {
            rust_source_dir: self.rust_source_dir.unwrap(),
            proto_file_output_dir: self.proto_file_output_dir.unwrap(),
            rust_mod_dir: self.rust_mod_dir.unwrap(),
            flutter_mod_dir: self.flutter_mod_dir.unwrap(),
            derive_meta_dir: self.derive_meta_dir.unwrap(),
        }
    }
}
