use crate::util::md5;
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use std::{convert::TryFrom, fmt::Formatter, ops::RangeInclusive};

#[derive(PartialEq, Eq, Clone, Default, Serialize, Deserialize)]
pub struct Revision {
    pub base_rev_id: i64,
    pub rev_id: i64,
    pub bytes: Vec<u8>,
    pub md5: String,
    pub object_id: String,
}

impl std::convert::From<Vec<u8>> for Revision {
    fn from(data: Vec<u8>) -> Self {
        let bytes = Bytes::from(data);
        Revision::try_from(bytes).unwrap()
    }
}

impl std::convert::TryFrom<Bytes> for Revision {
    type Error = serde_json::Error;

    fn try_from(bytes: Bytes) -> Result<Self, Self::Error> {
        serde_json::from_slice(&bytes)
    }
}

impl Revision {
    pub fn new<T: Into<String>>(object_id: &str, base_rev_id: i64, rev_id: i64, bytes: Bytes, md5: T) -> Revision {
        let object_id = object_id.to_owned();
        let bytes = bytes.to_vec();
        let base_rev_id = base_rev_id;
        let rev_id = rev_id;

        if base_rev_id != 0 {
            debug_assert!(base_rev_id <= rev_id);
        }

        Self {
            base_rev_id,
            rev_id,
            bytes,
            md5: md5.into(),
            object_id,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.base_rev_id == self.rev_id
    }

    pub fn pair_rev_id(&self) -> (i64, i64) {
        (self.base_rev_id, self.rev_id)
    }

    pub fn is_initial(&self) -> bool {
        self.rev_id == 0
    }

    pub fn initial_revision(object_id: &str, bytes: Bytes) -> Self {
        let md5 = md5(&bytes);
        Self::new(object_id, 0, 0, bytes, md5)
    }
}

impl std::fmt::Debug for Revision {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        f.write_fmt(format_args!("object_id {}, ", self.object_id))?;
        f.write_fmt(format_args!("base_rev_id {}, ", self.base_rev_id))?;
        f.write_fmt(format_args!("rev_id {}, ", self.rev_id))?;
        Ok(())
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RevisionRange {
    pub start: i64,
    pub end: i64,
}

impl std::fmt::Display for RevisionRange {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("[{},{}]", self.start, self.end))
    }
}

impl RevisionRange {
    pub fn len(&self) -> u64 {
        debug_assert!(self.end >= self.start);
        if self.end >= self.start {
            (self.end - self.start + 1) as u64
        } else {
            0
        }
    }

    pub fn is_empty(&self) -> bool {
        self.end == self.start
    }

    pub fn iter(&self) -> RangeInclusive<i64> {
        // debug_assert!(self.start != self.end);
        RangeInclusive::new(self.start, self.end)
    }

    pub fn to_rev_ids(&self) -> Vec<i64> {
        self.iter().collect::<Vec<_>>()
    }
}
