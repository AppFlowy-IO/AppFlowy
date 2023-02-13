#[rustfmt::skip]
/*
diesel master support on_conflict on sqlite but not 1.4.7 version. Workaround for this

match dsl::workspace_table
    .filter(workspace_table::id.eq(table.id.clone()))
    .count()
    .get_result(conn)
    .unwrap_or(0)
{
    0 => diesel::insert_into(workspace_table::table).values(table)
                    .on_conflict(workspace_table::id)
                    .do_update()
                    .set(WorkspaceTableChangeset::from_table(workspace_table))
                    .execute(conn)?,
    _ => {
        let changeset = WorkspaceTableChangeset::from_table(table);
        let filter = dsl::workspace_table.filter(workspace_table::id.eq(changeset.id.clone()));
        diesel::update(filter).set(changeset).execute(conn)?;
    },
}

is equivalent to:

match diesel_record_count!(workspace_table, &table.id, conn) {
    0 => diesel_insert_table!(workspace_table, table, conn),
    _ => diesel_update_table!(workspace_table, WorkspaceTableChangeset::from_table(table), &*conn),
}
*/

#[macro_export]
macro_rules! diesel_insert_table {
    (
        $table_name:ident,
        $table:expr,
        $connection:expr
    ) => {
        {
        let _ = diesel::insert_into($table_name::table)
                    .values($table)
                    // .on_conflict($table_name::dsl::id)
                    // .do_update()
                    // .set(WorkspaceTableChangeset::from_table(workspace_table))
                    .execute($connection)?;
        }
    };
}

#[macro_export]
macro_rules! diesel_record_count {
  (
        $table_name:ident,
        $id:expr,
        $connection:expr
    ) => {
    $table_name::dsl::$table_name
      .filter($table_name::dsl::id.eq($id.clone()))
      .count()
      .get_result($connection)
      .unwrap_or(0);
  };
}

#[macro_export]
macro_rules! diesel_revision_record_count {
  (
        $table_name:expr,
        $filter:expr,
        $connection:expr
    ) => {
    $table_name
      .filter($table_name::dsl::id.eq($id))
      .count()
      .get_result($connection)
      .unwrap_or(0);
  };
}

#[macro_export]
macro_rules! diesel_update_table {
  (
        $table_name:ident,
        $changeset:expr,
        $connection:expr
    ) => {{
    let filter =
      $table_name::dsl::$table_name.filter($table_name::dsl::id.eq($changeset.id.clone()));
    let affected_row = diesel::update(filter)
      .set($changeset)
      .execute($connection)?;
    debug_assert_eq!(affected_row, 1);
  }};
}

#[macro_export]
macro_rules! diesel_delete_table {
  (
        $table_name:ident,
        $id:ident,
        $connection:ident
    ) => {
    let filter = $table_name::dsl::$table_name.filter($table_name::dsl::id.eq($id));
    let affected_row = diesel::delete(filter).execute(&*$connection)?;
    debug_assert_eq!(affected_row, 1);
  };
}

#[macro_export]
macro_rules! impl_sql_binary_expression {
  ($target:ident) => {
    impl diesel::serialize::ToSql<diesel::sql_types::Binary, diesel::sqlite::Sqlite> for $target {
      fn to_sql<W: std::io::Write>(
        &self,
        out: &mut diesel::serialize::Output<W, diesel::sqlite::Sqlite>,
      ) -> diesel::serialize::Result {
        let bytes: Vec<u8> = self.try_into().map_err(|e| format!("{:?}", e))?;
        diesel::serialize::ToSql::<diesel::sql_types::Binary, diesel::sqlite::Sqlite>::to_sql(
          &bytes, out,
        )
      }
    }
    // https://docs.diesel.rs/src/diesel/sqlite/types/mod.rs.html#30-33
    // impl FromSql<sql_types::Binary, Sqlite> for *const [u8] {
    //     fn from_sql(bytes: Option<&SqliteValue>) -> deserialize::Result<Self> {
    //         let bytes = not_none!(bytes).read_blob();
    //         Ok(bytes as *const _)
    //     }
    // }
    impl<DB> diesel::deserialize::FromSql<diesel::sql_types::Binary, DB> for $target
    where
      DB: diesel::backend::Backend,
      *const [u8]: diesel::deserialize::FromSql<diesel::sql_types::Binary, DB>,
    {
      fn from_sql(bytes: Option<&DB::RawValue>) -> diesel::deserialize::Result<Self> {
        let slice_ptr = <*const [u8] as diesel::deserialize::FromSql<
          diesel::sql_types::Binary,
          DB,
        >>::from_sql(bytes)?;
        let bytes = unsafe { &*slice_ptr };

        match $target::try_from(bytes) {
          Ok(object) => Ok(object),
          Err(e) => {
            log::error!(
              "{:?} deserialize from bytes fail. {:?}",
              std::any::type_name::<$target>(),
              e
            );
            panic!();
          },
        }
      }
    }
  };
}

#[macro_export]
macro_rules! impl_sql_integer_expression {
  ($target:ident) => {
    impl<DB> diesel::serialize::ToSql<Integer, DB> for $target
    where
      DB: diesel::backend::Backend,
      i32: diesel::serialize::ToSql<Integer, DB>,
    {
      fn to_sql<W: std::io::Write>(
        &self,
        out: &mut diesel::serialize::Output<W, DB>,
      ) -> diesel::serialize::Result {
        (*self as i32).to_sql(out)
      }
    }

    impl<DB> diesel::deserialize::FromSql<Integer, DB> for $target
    where
      DB: diesel::backend::Backend,
      i32: diesel::deserialize::FromSql<Integer, DB>,
    {
      fn from_sql(bytes: Option<&DB::RawValue>) -> diesel::deserialize::Result<Self> {
        let smaill_int = i32::from_sql(bytes)?;
        Ok($target::from(smaill_int))
      }
    }
  };
}

#[macro_export]
macro_rules! impl_rev_state_map {
  ($target:ident) => {
    impl std::convert::From<i32> for $target {
      fn from(value: i32) -> Self {
        match value {
          0 => $target::Sync,
          1 => $target::Ack,
          o => {
            tracing::error!("Unsupported rev state {}, fallback to RevState::Local", o);
            $target::Sync
          },
        }
      }
    }

    impl std::convert::From<$target> for RevisionState {
      fn from(s: $target) -> Self {
        match s {
          $target::Sync => RevisionState::Sync,
          $target::Ack => RevisionState::Ack,
        }
      }
    }

    impl std::convert::From<RevisionState> for $target {
      fn from(s: RevisionState) -> Self {
        match s {
          RevisionState::Sync => $target::Sync,
          RevisionState::Ack => $target::Ack,
        }
      }
    }
  };
}
