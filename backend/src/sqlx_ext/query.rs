use backend_service::errors::ServerError;
use sql_builder::SqlBuilder as InnerBuilder;
use sqlx::{postgres::PgArguments, Arguments, Encode, Postgres, Type};

enum BuilderType {
    Create,
    Select,
    Update,
    Delete,
}

pub struct SqlBuilder {
    table: String,
    fields: Vec<String>,
    filters: Vec<String>,
    fields_args: PgArguments,
    ty: BuilderType,
}

impl SqlBuilder {
    fn new(table: &str) -> Self {
        Self {
            table: table.to_owned(),
            fields: vec![],
            filters: vec![],
            fields_args: PgArguments::default(),
            ty: BuilderType::Select,
        }
    }

    pub fn create(table: &str) -> Self {
        let mut builder = Self::new(table);
        builder.ty = BuilderType::Create;
        builder
    }

    pub fn select(table: &str) -> Self {
        let mut builder = Self::new(table);
        builder.ty = BuilderType::Select;
        builder
    }

    pub fn update(table: &str) -> Self {
        let mut builder = Self::new(table);
        builder.ty = BuilderType::Update;
        builder
    }

    pub fn delete(table: &str) -> Self {
        let mut builder = Self::new(table);
        builder.ty = BuilderType::Delete;
        builder
    }

    pub fn add_arg<'a, T>(mut self, field: &str, arg: T) -> Self
    where
        T: 'a + Send + Encode<'a, Postgres> + Type<Postgres>,
    {
        self.fields.push(field.to_owned());
        self.fields_args.add(arg);
        self
    }

    #[allow(dead_code)]
    pub fn add_arg_if<'a, T>(self, add: bool, field: &str, arg: T) -> Self
    where
        T: 'a + Send + Encode<'a, Postgres> + Type<Postgres>,
    {
        if add {
            self.add_arg(field, arg)
        } else {
            self
        }
    }

    pub fn add_some_arg<'a, T>(self, field: &str, arg: Option<T>) -> Self
    where
        T: 'a + Send + Encode<'a, Postgres> + Type<Postgres>,
    {
        if let Some(arg) = arg {
            self.add_arg(field, arg)
        } else {
            self
        }
    }

    pub fn add_field(mut self, field: &str) -> Self {
        self.fields.push(field.to_owned());
        self
    }

    pub fn and_where_eq<'a, T>(mut self, field: &str, arg: T) -> Self
    where
        T: 'a + Send + Encode<'a, Postgres> + Type<Postgres>,
    {
        self.filters.push(field.to_owned());
        self.fields_args.add(arg);
        self
    }

    pub fn build(self) -> Result<(String, PgArguments), ServerError> {
        match self.ty {
            BuilderType::Create => {
                let mut inner = InnerBuilder::insert_into(&self.table);
                self.fields.iter().for_each(|field| {
                    inner.field(field);
                });

                let values = self
                    .fields
                    .iter()
                    .enumerate()
                    .map(|(index, _)| format!("${}", index + 1))
                    .collect::<Vec<String>>();

                inner.values(&values);

                let sql = inner.sql()?;
                Ok((sql, self.fields_args))
            },
            BuilderType::Select => {
                let mut inner = InnerBuilder::select_from(&self.table);
                self.fields.into_iter().for_each(|field| {
                    inner.field(field);
                });

                self.filters.into_iter().enumerate().for_each(|(index, filter)| {
                    inner.and_where_eq(filter, format!("${}", index + 1));
                });

                let sql = inner.sql()?;
                Ok((sql, self.fields_args))
            },
            BuilderType::Update => {
                let mut inner = InnerBuilder::update_table(&self.table);
                let field_len = self.fields.len();
                self.fields.into_iter().enumerate().for_each(|(index, field)| {
                    inner.set(&field, format!("${}", index + 1));
                });

                self.filters.into_iter().enumerate().for_each(|(index, filter)| {
                    let index = index + field_len;
                    inner.and_where_eq(filter, format!("${}", index + 1));
                });

                let sql = inner.sql()?;
                Ok((sql, self.fields_args))
            },
            BuilderType::Delete => {
                let mut inner = InnerBuilder::delete_from(&self.table);
                self.filters.into_iter().enumerate().for_each(|(index, filter)| {
                    inner.and_where_eq(filter, format!("${}", index + 1));
                });
                let sql = inner.sql()?;
                Ok((sql, self.fields_args))
            },
        }
    }
}
