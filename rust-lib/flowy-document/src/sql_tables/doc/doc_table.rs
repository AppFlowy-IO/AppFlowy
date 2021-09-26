use crate::entities::doc::Doc;
use flowy_database::schema::doc_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "doc_table"]
pub(crate) struct DocTable {
    pub(crate) id: String,
    pub(crate) data: String,
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
    pub data: String,
    pub revision: i64,
}

impl std::convert::Into<Doc> for DocTable {
    fn into(self) -> Doc {
        Doc {
            id: self.id,
            data: self.data,
            rev_id: self.revision,
        }
    }
}

impl std::convert::From<Doc> for DocTable {
    fn from(doc: Doc) -> Self {
        Self {
            id: doc.id,
            data: doc.data,
            revision: doc.rev_id,
        }
    }
}
