use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_ot::rich_text::RichTextDelta;
use std::{convert::TryFrom, fmt::Formatter, ops::RangeInclusive};

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
    pub object_id: String,

    #[pb(index = 6)]
    ty: RevType, // Deprecated

    #[pb(index = 7)]
    pub user_id: String,
}

impl std::convert::From<Vec<u8>> for Revision {
    fn from(data: Vec<u8>) -> Self {
        let bytes = Bytes::from(data);
        Revision::try_from(bytes).unwrap()
    }
}

impl Revision {
    pub fn is_empty(&self) -> bool {
        self.base_rev_id == self.rev_id
    }

    pub fn pair_rev_id(&self) -> (i64, i64) {
        (self.base_rev_id, self.rev_id)
    }

    pub fn is_initial(&self) -> bool {
        self.rev_id == 0
    }

    pub fn initial_revision(user_id: &str, object_id: &str, delta_data: Bytes) -> Self {
        let md5 = md5(&delta_data);
        Self::new(object_id, 0, 0, delta_data, user_id, md5)
    }

    pub fn new(
        object_id: &str,
        base_rev_id: i64,
        rev_id: i64,
        delta_data: Bytes,
        user_id: &str,
        md5: String,
    ) -> Revision {
        let user_id = user_id.to_owned();
        let object_id = object_id.to_owned();
        let delta_data = delta_data.to_vec();
        let base_rev_id = base_rev_id;
        let rev_id = rev_id;

        if base_rev_id != 0 {
            debug_assert!(base_rev_id != rev_id);
        }

        Self {
            base_rev_id,
            rev_id,
            delta_data,
            md5,
            object_id,
            ty: RevType::DeprecatedLocal,
            user_id,
        }
    }
}

impl std::convert::From<Revision> for RepeatedRevision {
    fn from(revision: Revision) -> Self {
        RepeatedRevision { items: vec![revision] }
    }
}

impl std::fmt::Debug for Revision {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        let _ = f.write_fmt(format_args!("object_id {}, ", self.object_id))?;
        let _ = f.write_fmt(format_args!("base_rev_id {}, ", self.base_rev_id))?;
        let _ = f.write_fmt(format_args!("rev_id {}, ", self.rev_id))?;
        match RichTextDelta::from_bytes(&self.delta_data) {
            Ok(delta) => {
                let _ = f.write_fmt(format_args!("delta {:?}", delta.to_delta_json()))?;
            }
            Err(e) => {
                let _ = f.write_fmt(format_args!("delta {:?}", e))?;
            }
        }
        Ok(())
    }
}

#[derive(PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedRevision {
    #[pb(index = 1)]
    items: Vec<Revision>,
}

impl std::ops::Deref for RepeatedRevision {
    type Target = Vec<Revision>;

    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedRevision {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl RepeatedRevision {
    pub fn new(mut items: Vec<Revision>) -> Self {
        items.sort_by(|a, b| a.rev_id.cmp(&b.rev_id));
        Self { items }
    }

    pub fn empty() -> Self {
        RepeatedRevision { items: vec![] }
    }

    pub fn into_inner(self) -> Vec<Revision> {
        self.items
    }
}

#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct RevId {
    #[pb(index = 1)]
    pub value: i64,
}

impl AsRef<i64> for RevId {
    fn as_ref(&self) -> &i64 {
        &self.value
    }
}

impl std::convert::From<RevId> for i64 {
    fn from(rev_id: RevId) -> Self {
        rev_id.value
    }
}

impl std::convert::From<i64> for RevId {
    fn from(value: i64) -> Self {
        RevId { value }
    }
}

impl std::fmt::Display for RevId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("{}", self.value))
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RevisionRange {
    #[pb(index = 1)]
    pub start: i64,

    #[pb(index = 2)]
    pub end: i64,
}

impl std::fmt::Display for RevisionRange {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_fmt(format_args!("[{},{}]", self.start, self.end))
    }
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

#[inline]
pub fn md5<T: AsRef<[u8]>>(data: T) -> String {
    let md5 = format!("{:x}", md5::compute(data));
    md5
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum RevisionState {
    Sync = 0,
    Ack = 1,
}

impl RevisionState {
    pub fn is_need_sync(&self) -> bool {
        match self {
            RevisionState::Sync => true,
            RevisionState::Ack => false,
        }
    }
}

impl AsRef<RevisionState> for RevisionState {
    fn as_ref(&self) -> &RevisionState {
        self
    }
}

#[derive(Debug, ProtoBuf_Enum, Clone, Eq, PartialEq)]
pub enum RevType {
    DeprecatedLocal = 0,
    DeprecatedRemote = 1,
}

impl std::default::Default for RevType {
    fn default() -> Self {
        RevType::DeprecatedLocal
    }
}
