use crate::entities::trash::Trash;
use diesel::sql_types::Binary;
use flowy_database::schema::trash_table;

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "trash_table"]
pub(crate) struct TrashTable {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub modified_time: i64,
    pub create_time: i64,
}

impl std::convert::Into<Trash> for TrashTable {
    fn into(self) -> Trash {
        Trash {
            id: self.id,
            name: self.name,
            modified_time: self.modified_time,
            create_time: self.create_time,
        }
    }
}
