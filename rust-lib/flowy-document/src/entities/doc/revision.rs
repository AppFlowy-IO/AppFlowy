use crate::services::util::md5;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_ot::core::Delta;
use std::fmt::Formatter;

#[derive(Debug, ProtoBuf_Enum, Clone, Eq, PartialEq)]
pub enum RevType {
    Local  = 0,
    Remote = 1,
}

impl RevType {
    pub fn is_local(&self) -> bool { self == &RevType::Local }
}

impl std::default::Default for RevType {
    fn default() -> Self { RevType::Local }
}

// [[i64 to bytes]]
// use byteorder::{BigEndian, ReadBytesExt};
// use std::{io::Cursor};
// impl std::convert::TryFrom<Bytes> for RevId {
//     type Error = DocError;
//
//     fn try_from(bytes: Bytes) -> Result<Self, Self::Error> {
//         // let mut wtr = vec![];
//         // let _ = wtr.write_i64::<BigEndian>(revision.rev_id);
//
//         let mut rdr = Cursor::new(bytes);
//         match rdr.read_i64::<BigEndian>() {
//             Ok(rev_id) => Ok(RevId(rev_id)),
//             Err(e) => Err(DocError::internal().context(e)),
//         }
//     }
// }

#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct RevId {
    #[pb(index = 1)]
    pub inner: i64,
}

impl AsRef<i64> for RevId {
    fn as_ref(&self) -> &i64 { &self.inner }
}

impl std::convert::Into<i64> for RevId {
    fn into(self) -> i64 { self.inner }
}

impl std::convert::From<i64> for RevId {
    fn from(value: i64) -> Self { RevId { inner: value } }
}

impl std::fmt::Display for RevId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_fmt(format_args!("{}", self.inner)) }
}

#[derive(PartialEq, Eq, Clone, Default, ProtoBuf)]
pub struct Revision {
    #[pb(index = 1)]
    pub base_rev_id: i64,

    #[pb(index = 2)]
    pub rev_id: i64,

    #[pb(index = 3)]
    pub delta_data: Vec<u8>,

    #[pb(index = 4)]
    pub md5: String,

    #[pb(index = 5)]
    pub doc_id: String,

    #[pb(index = 6)]
    pub ty: RevType,
}

impl std::fmt::Debug for Revision {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        let _ = f.write_fmt(format_args!("doc_id {}, ", self.doc_id))?;
        let _ = f.write_fmt(format_args!("rev_id {}, ", self.rev_id))?;
        match Delta::from_bytes(&self.delta_data) {
            Ok(delta) => {
                let _ = f.write_fmt(format_args!("delta {:?}", delta.to_json()))?;
            },
            Err(e) => {
                let _ = f.write_fmt(format_args!("delta {:?}", e))?;
            },
        }
        Ok(())
    }
}

impl Revision {
    pub fn new<T1: Into<i64>, T2: Into<i64>>(
        base_rev_id: T1,
        rev_id: T2,
        delta_data: Vec<u8>,
        doc_id: &str,
        ty: RevType,
    ) -> Revision {
        let md5 = md5(&delta_data);
        let doc_id = doc_id.to_owned();
        Self {
            base_rev_id: base_rev_id.into(),
            rev_id: rev_id.into(),
            delta_data,
            md5,
            doc_id,
            ty,
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RevisionRange {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub from_rev_id: i64,

    #[pb(index = 3)]
    pub to_rev_id: i64,
}
