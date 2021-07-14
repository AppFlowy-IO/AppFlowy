use flowy_database::schema::user_table;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct User {
    pub(crate) id: String,
    pub(crate) name: String,
    password: String,
    pub(crate) email: String,
}

impl User {
    pub fn new(id: String, name: String, email: String, password: String) -> Self {
        Self {
            id,
            name,
            email,
            password,
        }
    }
}
