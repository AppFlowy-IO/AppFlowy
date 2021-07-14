#[macro_export]
macro_rules! impl_sql_binary_expression {
    ($target:ident) => {
        impl diesel::serialize::ToSql<diesel::sql_types::Binary, diesel::sqlite::Sqlite>
            for $target
        {
            fn to_sql<W: std::io::Write>(
                &self,
                out: &mut diesel::serialize::Output<W, diesel::sqlite::Sqlite>,
            ) -> diesel::serialize::Result {
                let bytes: Vec<u8> = self.try_into().map_err(|e| format!("{:?}", e))?;
                diesel::serialize::ToSql::<
                                                                        diesel::sql_types::Binary,
                                                                        diesel::sqlite::Sqlite,
                                                                    >::to_sql(&bytes, out)

                // match self.try_into() {
                //     Ok(bytes) => diesel::serialize::ToSql::<
                //         diesel::sql_types::Binary,
                //         diesel::sqlite::Sqlite,
                //     >::to_sql(&bytes, out),
                //     Err(e) => {
                //         log::error!(
                //             "{:?} serialize to bytes fail. {:?}",
                //             std::any::type_name::<$target>(),
                //             e
                //         );
                //         panic!();
                //     },
                // }
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
