use tokio_postgres::types::ToSql;

pub struct UpdateSqlBuilder {
  table: String,
  sets: Vec<(String, Box<dyn ToSql + Sync + Send>)>,
  where_clause: Option<(String, Box<dyn ToSql + Sync + Send>)>,
}

impl UpdateSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      sets: Vec::new(),
      where_clause: None,
    }
  }

  pub fn set<T: 'static + ToSql + Sync + Send>(mut self, column: &str, value: Option<T>) -> Self {
    if let Some(value) = value {
      self.sets.push((column.to_string(), Box::new(value)));
    }
    self
  }

  pub fn where_clause<T: 'static + ToSql + Sync + Send>(mut self, clause: &str, value: T) -> Self {
    self.where_clause = Some((clause.to_string(), Box::new(value)));
    self
  }

  pub fn build(self) -> (String, Vec<Box<dyn ToSql + Sync + Send>>) {
    let mut sql = format!("UPDATE {} SET ", self.table);

    for i in 0..self.sets.len() {
      if i > 0 {
        sql.push_str(", ");
      }
      sql.push_str(&format!("{} = ${}", self.sets[i].0, i + 1));
    }

    let mut params: Vec<_> = self.sets.into_iter().map(|(_, value)| value).collect();

    if let Some((clause, value)) = self.where_clause {
      sql.push_str(&format!(" WHERE {} = ${}", clause, params.len() + 1));
      params.push(value);
    }

    (sql, params)
  }
}

pub struct SelectSqlBuilder {
  table: String,
  columns: Vec<String>,
  where_clause: Option<(String, Box<dyn ToSql + Sync + Send>)>,
}

impl SelectSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      columns: Vec::new(),
      where_clause: None,
    }
  }

  pub fn column(mut self, column: &str) -> Self {
    self.columns.push(column.to_string());
    self
  }

  pub fn where_clause<T: 'static + ToSql + Sync + Send>(mut self, clause: &str, value: T) -> Self {
    self.where_clause = Some((clause.to_string(), Box::new(value)));
    self
  }

  pub fn build(self) -> (String, Vec<Box<dyn ToSql + Sync + Send>>) {
    let mut sql = format!("SELECT {} FROM {}", self.columns.join(", "), self.table);

    let mut params: Vec<_> = Vec::new();

    if let Some((clause, value)) = self.where_clause {
      sql.push_str(&format!(" WHERE {} = ${}", clause, params.len() + 1));
      params.push(value);
    }

    (sql, params)
  }
}

pub struct InsertSqlBuilder {
  table: String,
  columns: Vec<String>,
  values: Vec<Box<(dyn ToSql + Sync + Send + 'static)>>,
}

impl InsertSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      columns: Vec::new(),
      values: Vec::new(),
    }
  }

  pub fn value<T: ToSql + Sync + Send + 'static>(mut self, column: &str, value: T) -> Self {
    self.columns.push(column.to_string());
    self.values.push(Box::new(value));
    self
  }

  pub fn build(self) -> (String, Vec<Box<(dyn ToSql + Sync + Send)>>) {
    let mut query = format!("INSERT INTO {} (", self.table);
    query.push_str(&self.columns.join(", "));
    query.push_str(") VALUES (");
    query.push_str(
      &(0..self.columns.len())
        .map(|i| format!("${}", i + 1))
        .collect::<Vec<_>>()
        .join(", "),
    );
    query.push(')');
    (query, self.values)
  }
}
