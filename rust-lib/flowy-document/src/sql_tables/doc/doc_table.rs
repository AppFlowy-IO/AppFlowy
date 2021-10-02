use crate::entities::doc::Doc;
use flowy_database::schema::doc_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "doc_table"]
pub(crate) struct DocTable {
    pub(crate) id: String,
    pub(crate) data: String,
    pub(crate) rev_id: i64,
}

impl DocTable {
    pub fn new(doc: Doc) -> Self {
        Self {
            id: doc.id,
            data: doc.data,
            rev_id: doc.rev_id.into(),
        }
    }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "doc_table"]
pub(crate) struct DocTableChangeset {
    pub id: String,
    pub data: String,
    pub rev_id: i64,
}

impl std::convert::Into<Doc> for DocTable {
    fn into(self) -> Doc {
        Doc {
            id: self.id,
            data: self.data,
            rev_id: self.rev_id.into(),
        }
    }
}

impl std::convert::From<Doc> for DocTable {
    fn from(doc: Doc) -> Self {
        Self {
            id: doc.id,
            data: doc.data,
            rev_id: doc.rev_id.into(),
        }
    }
}
