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
  where_clause_in: Option<(String, Vec<Box<dyn ToSql + Sync + Send>>)>,
  group_by_column: Option<String>,
  order_by: Option<(String, bool)>,
  limit: Option<i64>,
  lock: bool,
  array_agg_columns: Vec<String>,
}

impl SelectSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      columns: Vec::new(),
      where_clause: None,
      where_clause_in: None,
      group_by_column: None,
      order_by: None,
      limit: None,
      lock: false,
      array_agg_columns: vec![],
    }
  }

  pub fn lock(mut self) -> Self {
    self.lock = true;
    self
  }

  pub fn column(mut self, column: &str) -> Self {
    self.columns.push(column.to_string());
    self
  }

  pub fn group_by(mut self, column: &str) -> Self {
    self.group_by_column = Some(column.to_string());
    self
  }

  pub fn array_agg(mut self, column: &str) -> Self {
    self.array_agg_columns.push(column.to_string());
    self
  }

  pub fn order_by(mut self, column: &str, asc: bool) -> Self {
    self.order_by = Some((column.to_string(), asc));
    self
  }

  pub fn where_clause<T: 'static + ToSql + Sync + Send>(mut self, clause: &str, value: T) -> Self {
    self.where_clause = Some((clause.to_string(), Box::new(value)));
    self
  }

  pub fn where_clause_in<T: 'static + ToSql + Sync + Send>(
    mut self,
    clause: &str,
    values: Vec<T>,
  ) -> Self {
    let boxed_values: Vec<_> = values
      .into_iter()
      .map(|value| Box::new(value) as Box<dyn ToSql + Send + Sync>)
      .collect();
    self.where_clause_in = Some((clause.to_string(), boxed_values));
    self
  }

  pub fn limit(mut self, limit: i64) -> Self {
    self.limit = Some(limit);
    self
  }

  pub fn build(self) -> (String, Vec<Box<dyn ToSql + Sync + Send>>) {
    let all_columns = self
      .columns
      .iter()
      .chain(self.array_agg_columns.iter())
      .cloned()
      .collect::<Vec<_>>()
      .join(", ");
    let mut sql = format!("SELECT {} FROM {}", all_columns, self.table);

    let mut params: Vec<_> = Vec::new();
    if let Some((clause, value)) = self.where_clause {
      sql.push_str(&format!(" WHERE {} = ${}", clause, params.len() + 1));
      params.push(value);
    }

    if let Some((clause, values)) = self.where_clause_in {
      let placeholders: Vec<String> = values
        .iter()
        .enumerate()
        .map(|(i, _)| format!("${}", i + 1))
        .collect();
      sql.push_str(&format!(
        " WHERE {} IN ({})",
        clause,
        placeholders.join(",")
      ));
      params.extend(values);
    }

    if let Some(group_by_column) = self.group_by_column {
      sql.push_str(&format!(" GROUP BY {}", group_by_column));
    }

    if let Some((order_by_column, asc)) = self.order_by {
      let order = if asc { "ASC" } else { "DESC" };
      sql.push_str(&format!(" ORDER BY {} {}", order_by_column, order));
    }

    // ARRAY_AGG is an aggregate function that concatenates the values from column_name
    // into an array.
    for array_agg_column in self.array_agg_columns {
      sql = sql.replace(
        &array_agg_column,
        &format!("ARRAY_AGG({}) as {}", array_agg_column, array_agg_column),
      );
    }

    if let Some(limit) = self.limit {
      sql.push_str(&format!(" LIMIT {}", limit));
    }

    if self.lock {
      sql.push_str(" FOR UPDATE");
    }

    (sql, params)
  }
}

pub struct InsertSqlBuilder {
  table: String,
  columns: Vec<String>,
  values: Vec<Box<(dyn ToSql + Sync + Send + 'static)>>,
  override_system_value: bool,
  returning: Vec<String>, // Vec for returning multiple columns
}

impl InsertSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      columns: Vec::new(),
      values: Vec::new(),
      override_system_value: false,
      returning: vec![],
    }
  }

  pub fn value<T: ToSql + Sync + Send + 'static>(mut self, column: &str, value: T) -> Self {
    self.columns.push(column.to_string());
    self.values.push(Box::new(value));
    self
  }

  pub fn overriding_system_value(mut self) -> Self {
    self.override_system_value = true;
    self
  }

  pub fn returning(mut self, column: &str) -> Self {
    // add column to return
    self.returning.push(column.to_string());
    self
  }

  pub fn build(self) -> (String, Vec<Box<(dyn ToSql + Sync + Send)>>) {
    let mut query = format!("INSERT INTO {} (", self.table);
    query.push_str(&self.columns.join(", "));
    query.push(')');

    if self.override_system_value {
      query.push_str(" OVERRIDING SYSTEM VALUE");
    }

    query.push_str(" VALUES (");
    query.push_str(
      &(0..self.columns.len())
        .map(|i| format!("${}", i + 1))
        .collect::<Vec<_>>()
        .join(", "),
    );
    query.push(')');

    if !self.returning.is_empty() {
      // add RETURNING clause if there are columns to return
      query.push_str(&format!(" RETURNING {}", self.returning.join(", ")));
    }

    (query, self.values)
  }
}

pub enum WhereCondition {
  Equals(String, Box<dyn ToSql + Sync + Send>),
  In(String, Vec<Box<dyn ToSql + Sync + Send>>),
}

pub struct DeleteSqlBuilder {
  table: String,
  conditions: Vec<WhereCondition>,
}

impl DeleteSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      conditions: Vec::new(),
    }
  }

  pub fn where_condition(mut self, condition: WhereCondition) -> Self {
    self.conditions.push(condition);
    self
  }

  pub fn build(self) -> (String, Vec<Box<dyn ToSql + Sync + Send>>) {
    let mut sql = format!("DELETE FROM {}", self.table);
    let mut params: Vec<Box<dyn ToSql + Sync + Send>> = Vec::new();

    if !self.conditions.is_empty() {
      sql.push_str(" WHERE ");
      let condition_len = self.conditions.len();
      for (i, condition) in self.conditions.into_iter().enumerate() {
        match condition {
          WhereCondition::Equals(column, value) => {
            sql.push_str(&format!(
              "{} = ${}{}",
              column,
              params.len() + 1,
              if i < condition_len - 1 { " AND " } else { "" },
            ));
            params.push(value);
          },
          WhereCondition::In(column, values) => {
            let placeholders: Vec<String> = (1..=values.len())
              .map(|i| format!("${}", i + params.len()))
              .collect();
            sql.push_str(&format!(
              "{} IN ({}){}",
              column,
              placeholders.join(", "),
              if i < condition_len - 1 { " AND " } else { "" },
            ));
            params.extend(values);
          },
        }
      }
    }

    (sql, params)
  }
}
