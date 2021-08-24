use sqlx::{any::AnyArguments, Arguments, Encode, PgPool, Postgres, Type};

use sqlx::postgres::PgArguments;

pub struct UpdateBuilder {
    arguments: PgArguments,
    table: String,
    fields: String,
}

impl UpdateBuilder {
    pub fn new(table: &str) -> Self {
        Self {
            table: table.to_owned(),
            fields: String::new(),
            arguments: PgArguments::default(),
        }
    }

    pub fn add_argument<'a, T>(&mut self, column: &str, arg: Option<T>)
    where
        T: 'a + Send + Encode<'a, Postgres> + Type<Postgres>,
    {
        if let Some(arg) = arg {
            if self.fields.is_empty() {
                self.fields += &format!("{}=?", column);
            } else {
                self.fields += &format!(", {}=?", column);
            }
            self.arguments.add(arg);
        }
    }

    pub fn build(self) -> (String, PgArguments) {
        let sql = format!("UPDATE {} SET {} WHERE id=?", self.table, self.fields);
        (sql, self.arguments)
    }
}
