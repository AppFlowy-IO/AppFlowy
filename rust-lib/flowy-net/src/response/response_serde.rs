// use crate::response::{FlowyResponse, ServerCode};
// use serde::{
//     de::{self, MapAccess, Visitor},
//     Deserialize,
//     Deserializer,
//     Serialize,
// };
// use std::{fmt, marker::PhantomData, str::FromStr};
//
// pub trait ServerData<'a>: Serialize + Deserialize<'a> + FromStr<Err = ()> {}
// impl<'de, T: ServerData<'de>> Deserialize<'de> for FlowyResponse<T> {
//     fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
//     where
//         D: Deserializer<'de>,
//     {
//         struct ServerResponseVisitor<T>(PhantomData<fn() -> T>);
//         impl<'de, T> Visitor<'de> for ServerResponseVisitor<T>
//         where
//             T: ServerData<'de>,
//         {
//             type Value = FlowyResponse<T>;
//
//             fn expecting(&self, formatter: &mut fmt::Formatter) ->
// fmt::Result {                 formatter.write_str("struct Duration")
//             }
//
//             fn visit_map<V>(self, mut map: V) -> Result<Self::Value,
// V::Error>             where
//                 V: MapAccess<'de>,
//             {
//                 let mut msg = None;
//                 let mut data: Option<T> = None;
//                 let mut code: Option<ServerCode> = None;
//                 while let Some(key) = map.next_key()? {
//                     match key {
//                         "msg" => {
//                             if msg.is_some() {
//                                 return
// Err(de::Error::duplicate_field("msg"));                             }
//                             msg = Some(map.next_value()?);
//                         },
//                         "code" => {
//                             if code.is_some() {
//                                 return
// Err(de::Error::duplicate_field("code"));                             }
//                             code = Some(map.next_value()?);
//                         },
//                         "data" => {
//                             if data.is_some() {
//                                 return
// Err(de::Error::duplicate_field("data"));                             }
//                             data = match
// MapAccess::next_value::<DeserializeWith<T>>(&mut map) {                      
// Ok(wrapper) => wrapper.value,                                 Err(err) =>
// return Err(err),                             };
//                         },
//                         _ => panic!(),
//                     }
//                 }
//                 let msg = msg.ok_or_else(||
// de::Error::missing_field("msg"))?;                 let code =
// code.ok_or_else(|| de::Error::missing_field("code"))?;                 
// Ok(Self::Value::new(data, msg, code))             }
//         }
//         const FIELDS: &'static [&'static str] = &["msg", "code", "data"];
//         deserializer.deserialize_struct(
//             "ServerResponse",
//             FIELDS,
//             ServerResponseVisitor(PhantomData),
//         )
//     }
// }
//
// struct DeserializeWith<'de, T: ServerData<'de>> {
//     value: Option<T>,
//     phantom: PhantomData<&'de ()>,
// }
//
// impl<'de, T: ServerData<'de>> Deserialize<'de> for DeserializeWith<'de, T> {
//     fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
//     where
//         D: Deserializer<'de>,
//     {
//         Ok(DeserializeWith {
//             value: match string_or_data(deserializer) {
//                 Ok(val) => val,
//                 Err(e) => return Err(e),
//             },
//             phantom: PhantomData,
//         })
//     }
// }
//
// fn string_or_data<'de, D, T>(deserializer: D) -> Result<Option<T>, D::Error>
// where
//     D: Deserializer<'de>,
//     T: ServerData<'de>,
// {
//     struct StringOrData<T>(PhantomData<fn() -> T>);
//     impl<'de, T: ServerData<'de>> Visitor<'de> for StringOrData<T> {
//         type Value = Option<T>;
//
//         fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
//             formatter.write_str("string or struct impl deserialize")
//         }
//
//         fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
//         where
//             E: de::Error,
//         {
//             match FromStr::from_str(value) {
//                 Ok(val) => Ok(Some(val)),
//                 Err(_e) => Ok(None),
//             }
//         }
//
//         fn visit_map<M>(self, map: M) -> Result<Self::Value, M::Error>
//         where
//             M: MapAccess<'de>,
//         {
//             match
// Deserialize::deserialize(de::value::MapAccessDeserializer::new(map)) {
//                 Ok(val) => Ok(Some(val)),
//                 Err(e) => Err(e),
//             }
//         }
//     }
//     deserializer.deserialize_any(StringOrData(PhantomData))
// }
