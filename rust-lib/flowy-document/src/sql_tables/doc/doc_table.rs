use crate::entities::doc::{Doc, UpdateDocParams};
use flowy_database::schema::doc_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "doc_table"]
pub(crate) struct DocTable {
    pub(crate) id: String,
    pub(crate) data: Vec<u8>,
    pub(crate) revision: i64,
}

impl DocTable {
    pub fn new(doc: Doc) -> Self {
        Self {
            id: doc.id,
            data: doc.data,
            revision: 0,
        }
    }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "doc_table"]
pub(crate) struct DocTableChangeset {
    pub id: String,
    pub data: Vec<u8>,
}

impl DocTableChangeset {
    pub(crate) fn new(params: UpdateDocParams) -> Self {
        Self {
            id: params.doc_id,
            data: params.data,
        }
    }
}

impl std::convert::Into<Doc> for DocTable {
    fn into(self) -> Doc {
        Doc {
            id: self.id,
            data: self.data,
            revision: self.revision,
        }
    }
}

impl std::convert::From<Doc> for DocTable {
    fn from(doc: Doc) -> Self {
        Self {
            id: doc.id,
            data: doc.data,
            revision: doc.revision,
        }
    }
}
