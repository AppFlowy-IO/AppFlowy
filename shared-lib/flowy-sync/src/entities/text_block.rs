use crate::{
    entities::revision::{RepeatedRevision, Revision},
    errors::CollaborateError,
};
use flowy_derive::ProtoBuf;
use lib_ot::{errors::OTError, text_delta::TextDelta};

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateTextBlockParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub revisions: RepeatedRevision,
}

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct DocumentPB {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub text: String,

    #[pb(index = 3)]
    pub rev_id: i64,

    #[pb(index = 4)]
    pub base_rev_id: i64,
}

impl DocumentPB {
    pub fn delta(&self) -> Result<TextDelta, OTError> {
        let delta = TextDelta::from_bytes(&self.text)?;
        Ok(delta)
    }
}

impl std::convert::TryFrom<Revision> for DocumentPB {
    type Error = CollaborateError;

    fn try_from(revision: Revision) -> Result<Self, Self::Error> {
        if !revision.is_initial() {
            return Err(CollaborateError::revision_conflict()
                .context("Revision's rev_id should be 0 when creating the document"));
        }

        let delta = TextDelta::from_bytes(&revision.delta_data)?;
        let doc_json = delta.json_str();

        Ok(DocumentPB {
            block_id: revision.object_id,
            text: doc_json,
            rev_id: revision.rev_id,
            base_rev_id: revision.base_rev_id,
        })
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ResetTextBlockParams {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub revisions: RepeatedRevision,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct TextBlockDeltaPB {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub delta_str: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct NewDocUserPB {
    #[pb(index = 1)]
    pub user_id: String,

    #[pb(index = 2)]
    pub rev_id: i64,

    #[pb(index = 3)]
    pub doc_id: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct TextBlockIdPB {
    #[pb(index = 1)]
    pub value: String,
}
impl AsRef<str> for TextBlockIdPB {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

impl std::convert::From<String> for TextBlockIdPB {
    fn from(value: String) -> Self {
        TextBlockIdPB { value }
    }
}

impl std::convert::From<TextBlockIdPB> for String {
    fn from(block_id: TextBlockIdPB) -> Self {
        block_id.value
    }
}

impl std::convert::From<&String> for TextBlockIdPB {
    fn from(s: &String) -> Self {
        TextBlockIdPB { value: s.to_owned() }
    }
}
