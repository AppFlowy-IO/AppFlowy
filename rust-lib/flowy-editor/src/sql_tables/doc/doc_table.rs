use crate::entities::doc::{CreateDocParams, DocDescription, UpdateDocParams};
use flowy_database::schema::doc_table;
use flowy_infra::{timestamp, uuid};
use std::convert::TryInto;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "doc_table"]
pub(crate) struct DocTable {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub path: String,
    pub modified_time: i64,
    pub create_time: i64,
    pub version: i64,
}

impl DocTable {
    pub fn new(params: CreateDocParams, path: &str) -> Self {
        let time = timestamp();
        Self {
            id: params.id,
            name: params.name,
            desc: params.desc,
            path: path.to_owned(),
            modified_time: time,
            create_time: time,
            version: 0,
        }
    }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "doc_table"]
pub(crate) struct DocTableChangeset {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
}

impl DocTableChangeset {
    pub(crate) fn new(params: UpdateDocParams) -> Self {
        Self {
            id: params.id,
            name: params.name,
            desc: params.desc,
        }
    }
}

impl std::convert::Into<DocDescription> for DocTable {
    fn into(self) -> DocDescription {
        DocDescription {
            id: self.id,
            name: self.name,
            desc: self.desc,
            path: self.path,
        }
    }
}
