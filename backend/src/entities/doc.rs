use flowy_document::protobuf::Doc;

pub(crate) const DOC_TABLE: &'static str = "doc_table";

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct DocTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) data: Vec<u8>,
}

impl std::convert::Into<Doc> for DocTable {
    fn into(self) -> Doc {
        let mut doc = Doc::new();
        doc.set_id(self.id.to_string());
        doc.set_data(self.data);
        doc
    }
}
