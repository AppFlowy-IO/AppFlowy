#[macro_export]
macro_rules! impl_sql_binary_expression {
    ($target:ident) => {
        impl diesel::serialize::ToSql<diesel::sql_types::Binary, diesel::sqlite::Sqlite> for $target {
            fn to_sql<W: std::io::Write>(
                &self,
                out: &mut diesel::serialize::Output<W, diesel::sqlite::Sqlite>,
            ) -> diesel::serialize::Result {
                let bytes: Vec<u8> = self.try_into().map_err(|e| format!("{:?}", e))?;
                diesel::serialize::ToSql::<diesel::sql_types::Binary, diesel::sqlite::Sqlite>::to_sql(&bytes, out)
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
                let slice_ptr = <*const [u8] as diesel::deserialize::FromSql<diesel::sql_types::Binary, DB>>::from_sql(bytes)?;
                let bytes = unsafe { &*slice_ptr };

                match $target::try_from(bytes) {
                    Ok(object) => Ok(object),
                    Err(e) => {
                        log::error!("{:?} deserialize from bytes fail. {:?}", std::any::type_name::<$target>(), e);
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
        use diesel::{
            deserialize,
            deserialize::FromSql,
            serialize,
            serialize::{Output, ToSql},
        };
        use std::io::Write;

        impl<DB> ToSql<Integer, DB> for $target
        where
            DB: diesel::backend::Backend,
            i32: ToSql<Integer, DB>,
        {
            fn to_sql<W: Write>(&self, out: &mut Output<W, DB>) -> serialize::Result { (*self as i32).to_sql(out) }
        }

        impl<DB> FromSql<Integer, DB> for $target
        where
            DB: diesel::backend::Backend,
            i32: FromSql<Integer, DB>,
        {
            fn from_sql(bytes: Option<&DB::RawValue>) -> deserialize::Result<Self> {
                let smaill_int = i32::from_sql(bytes)?;
                Ok($target::from(smaill_int))
            }
        }
    };
}
// #[macro_export]
// macro_rules! impl_save_func {
//     ($func_name:ident, $target:ident, $table_name:expr, $conn:ident) => {
//         fn $func_name(object: $target) -> Result<(), WorkspaceError> {
//             let _ = diesel::insert_into($table_name)
//                 .values($target)
//                 .execute(&*($conn))?;
//         }
//     };
// }

#[macro_export]
macro_rules! impl_def_and_def_mut {
    ($target:ident, $item: ident) => {
        impl std::ops::Deref for $target {
            type Target = Vec<$item>;

            fn deref(&self) -> &Self::Target { &self.items }
        }
        impl std::ops::DerefMut for $target {
            fn deref_mut(&mut self) -> &mut Self::Target { &mut self.items }
        }

        impl $target {
            #[allow(dead_code)]
            pub fn take_items(&mut self) -> Vec<$item> { ::std::mem::replace(&mut self.items, vec![]) }

            #[allow(dead_code)]
            pub fn push(&mut self, item: $item) {
                if self.items.contains(&item) {
                    log::error!("add duplicate item: {:?}", item);
                    return;
                }

                self.items.push(item);
            }

            pub fn first_or_crash(&self) -> &$item { self.items.first().unwrap() }
        }
    };
}
