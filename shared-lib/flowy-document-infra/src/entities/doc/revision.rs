use crate::{entities::doc::Doc, util::md5};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_ot::core::RichTextDelta;
use std::{fmt::Formatter, ops::RangeInclusive};

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
    pub value: i64,
}

impl AsRef<i64> for RevId {
    fn as_ref(&self) -> &i64 { &self.value }
}

impl std::convert::From<RevId> for i64 {
    fn from(rev_id: RevId) -> Self { rev_id.value }
}

impl std::convert::From<i64> for RevId {
    fn from(value: i64) -> Self { RevId { value } }
}

impl std::fmt::Display for RevId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_fmt(format_args!("{}", self.value)) }
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

impl Revision {
    pub fn is_empty(&self) -> bool { self.base_rev_id == self.rev_id }
}

impl std::fmt::Debug for Revision {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        let _ = f.write_fmt(format_args!("doc_id {}, ", self.doc_id))?;
        let _ = f.write_fmt(format_args!("base_rev_id {}, ", self.base_rev_id))?;
        let _ = f.write_fmt(format_args!("rev_id {}, ", self.rev_id))?;
        match RichTextDelta::from_bytes(&self.delta_data) {
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
    pub fn new<T1, T2, D>(base_rev_id: T1, rev_id: T2, delta: D, doc_id: &str, ty: RevType) -> Revision
    where
        T1: Into<i64>,
        T2: Into<i64>,
        D: AsRef<[u8]>,
    {
        let md5 = md5(&delta);
        let doc_id = doc_id.to_owned();
        let delta_data = delta.as_ref().to_vec();
        let base_rev_id = base_rev_id.into();
        let rev_id = rev_id.into();

        if base_rev_id != 0 {
            debug_assert!(base_rev_id != rev_id);
        }

        Self {
            base_rev_id,
            rev_id,
            delta_data,
            md5,
            doc_id,
            ty,
        }
    }
}

pub fn revision_from_doc(doc: Doc, ty: RevType) -> Revision {
    let delta_data = doc.data.as_bytes();
    Revision::new(doc.base_rev_id, doc.rev_id, delta_data.to_owned(), &doc.id, ty)
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RevisionRange {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub start: i64,

    #[pb(index = 3)]
    pub end: i64,
}

impl RevisionRange {
    pub fn len(&self) -> i64 {
        debug_assert!(self.end >= self.start);
        if self.end >= self.start {
            self.end - self.start + 1
        } else {
            0
        }
    }

    pub fn is_empty(&self) -> bool { self.end == self.start }

    pub fn iter(&self) -> RangeInclusive<i64> {
        debug_assert!(self.start != self.end);
        RangeInclusive::new(self.start, self.end)
    }
}
