use flowy_document_infra::protobuf::Doc;

pub(crate) const DOC_TABLE: &str = "doc_table";

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct DocTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) data: String,
    pub(crate) rev_id: i64,
}

impl std::convert::From<DocTable> for Doc {
    fn from(table: DocTable) -> Self {
        let mut doc = Doc::new();
        doc.set_id(table.id.to_string());
        doc.set_data(table.data);
        doc.set_rev_id(table.rev_id);
        doc
    }
}
