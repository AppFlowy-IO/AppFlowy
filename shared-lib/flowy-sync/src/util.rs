use crate::{
    entities::{
        folder::{FolderDelta, FolderInfo},
        revision::{RepeatedRevision, Revision},
        text_block::DocumentPB,
    },
    errors::{CollaborateError, CollaborateResult},
};
use dissimilar::Chunk;
use lib_ot::core::{DeltaBuilder, OTString, PhantomAttributes, TextDelta};
use lib_ot::{
    core::{Attributes, Delta, OperationTransform, NEW_LINE, WHITESPACE},
    rich_text::RichTextDelta,
};
use serde::de::DeserializeOwned;
use std::sync::atomic::{AtomicI64, Ordering::SeqCst};

#[inline]
pub fn find_newline(s: &str) -> Option<usize> {
    s.find(NEW_LINE)
}

#[inline]
pub fn is_newline(s: &str) -> bool {
    s == NEW_LINE
}

#[inline]
pub fn is_whitespace(s: &str) -> bool {
    s == WHITESPACE
}

#[inline]
pub fn contain_newline(s: &str) -> bool {
    s.contains(NEW_LINE)
}

#[inline]
pub fn md5<T: AsRef<[u8]>>(data: T) -> String {
    let md5 = format!("{:x}", md5::compute(data));
    md5
}

#[derive(Debug)]
pub struct RevIdCounter(pub AtomicI64);

impl RevIdCounter {
    pub fn new(n: i64) -> Self {
        Self(AtomicI64::new(n))
    }
    pub fn next(&self) -> i64 {
        let _ = self.0.fetch_add(1, SeqCst);
        self.value()
    }
    pub fn value(&self) -> i64 {
        self.0.load(SeqCst)
    }

    pub fn set(&self, n: i64) {
        let _ = self.0.fetch_update(SeqCst, SeqCst, |_| Some(n));
    }
}

#[tracing::instrument(level = "trace", skip(revisions), err)]
pub fn make_delta_from_revisions<T>(revisions: Vec<Revision>) -> CollaborateResult<Delta<T>>
where
    T: Attributes + DeserializeOwned,
{
    let mut delta = Delta::<T>::new();
    for revision in revisions {
        if revision.delta_data.is_empty() {
            tracing::warn!("revision delta_data is empty");
        }

        let revision_delta = Delta::<T>::from_bytes(revision.delta_data).map_err(|e| {
            let err_msg = format!("Deserialize remote revision failed: {:?}", e);
            CollaborateError::internal().context(err_msg)
        })?;
        delta = delta.compose(&revision_delta)?;
    }
    Ok(delta)
}

pub fn make_text_delta_from_revisions(revisions: Vec<Revision>) -> CollaborateResult<TextDelta> {
    make_delta_from_revisions::<PhantomAttributes>(revisions)
}

pub fn make_delta_from_revision_pb<T>(revisions: Vec<Revision>) -> CollaborateResult<Delta<T>>
where
    T: Attributes + DeserializeOwned,
{
    let mut new_delta = Delta::<T>::new();
    for revision in revisions {
        let delta = Delta::<T>::from_bytes(revision.delta_data).map_err(|e| {
            let err_msg = format!("Deserialize remote revision failed: {:?}", e);
            CollaborateError::internal().context(err_msg)
        })?;
        new_delta = new_delta.compose(&delta)?;
    }
    Ok(new_delta)
}

pub fn pair_rev_id_from_revision_pbs(revisions: &[Revision]) -> (i64, i64) {
    let mut rev_id = 0;
    revisions.iter().for_each(|revision| {
        if rev_id < revision.rev_id {
            rev_id = revision.rev_id;
        }
    });

    if rev_id > 0 {
        (rev_id - 1, rev_id)
    } else {
        (0, rev_id)
    }
}

pub fn pair_rev_id_from_revisions(revisions: &[Revision]) -> (i64, i64) {
    let mut rev_id = 0;
    revisions.iter().for_each(|revision| {
        if rev_id < revision.rev_id {
            rev_id = revision.rev_id;
        }
    });

    if rev_id > 0 {
        (rev_id - 1, rev_id)
    } else {
        (0, rev_id)
    }
}

#[inline]
pub fn make_folder_from_revisions_pb(
    folder_id: &str,
    revisions: RepeatedRevision,
) -> Result<Option<FolderInfo>, CollaborateError> {
    let revisions = revisions.into_inner();
    if revisions.is_empty() {
        return Ok(None);
    }

    let mut folder_delta = FolderDelta::new();
    let mut base_rev_id = 0;
    let mut rev_id = 0;
    for revision in revisions {
        base_rev_id = revision.base_rev_id;
        rev_id = revision.rev_id;
        if revision.delta_data.is_empty() {
            tracing::warn!("revision delta_data is empty");
        }
        let delta = FolderDelta::from_bytes(revision.delta_data)?;
        folder_delta = folder_delta.compose(&delta)?;
    }

    let text = folder_delta.json_str();
    Ok(Some(FolderInfo {
        folder_id: folder_id.to_string(),
        text,
        rev_id,
        base_rev_id,
    }))
}

#[inline]
pub fn make_document_from_revision_pbs(
    doc_id: &str,
    revisions: RepeatedRevision,
) -> Result<Option<DocumentPB>, CollaborateError> {
    let revisions = revisions.into_inner();
    if revisions.is_empty() {
        return Ok(None);
    }

    let mut delta = RichTextDelta::new();
    let mut base_rev_id = 0;
    let mut rev_id = 0;
    for revision in revisions {
        base_rev_id = revision.base_rev_id;
        rev_id = revision.rev_id;

        if revision.delta_data.is_empty() {
            tracing::warn!("revision delta_data is empty");
        }

        let new_delta = RichTextDelta::from_bytes(revision.delta_data)?;
        delta = delta.compose(&new_delta)?;
    }

    let text = delta.json_str();

    Ok(Some(DocumentPB {
        block_id: doc_id.to_owned(),
        text,
        rev_id,
        base_rev_id,
    }))
}

#[inline]
pub fn rev_id_from_str(s: &str) -> Result<i64, CollaborateError> {
    let rev_id = s
        .to_owned()
        .parse::<i64>()
        .map_err(|e| CollaborateError::internal().context(format!("Parse rev_id from {} failed. {}", s, e)))?;
    Ok(rev_id)
}

pub fn cal_diff<T: Attributes>(old: String, new: String) -> Option<Delta<T>> {
    let chunks = dissimilar::diff(&old, &new);
    let mut delta_builder = DeltaBuilder::<T>::new();
    for chunk in &chunks {
        match chunk {
            Chunk::Equal(s) => {
                delta_builder = delta_builder.retain(OTString::from(*s).utf16_len());
            }
            Chunk::Delete(s) => {
                delta_builder = delta_builder.delete(OTString::from(*s).utf16_len());
            }
            Chunk::Insert(s) => {
                delta_builder = delta_builder.insert(*s);
            }
        }
    }

    let delta = delta_builder.build();
    if delta.is_empty() {
        None
    } else {
        Some(delta)
    }
}
