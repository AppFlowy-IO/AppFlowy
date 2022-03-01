use crate::{
    entities::{
        document_info::BlockInfo,
        folder_info::{FolderDelta, FolderInfo},
        revision::{RepeatedRevision, Revision},
    },
    errors::{CollaborateError, CollaborateResult},
    protobuf::{
        BlockInfo as BlockInfoPB, FolderInfo as FolderInfoPB, RepeatedRevision as RepeatedRevisionPB,
        Revision as RevisionPB,
    },
};
use lib_ot::{
    core::{Attributes, Delta, OperationTransformable, NEW_LINE, WHITESPACE},
    rich_text::RichTextDelta,
};
use serde::de::DeserializeOwned;
use std::{
    convert::TryInto,
    sync::atomic::{AtomicI64, Ordering::SeqCst},
};

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

pub fn make_delta_from_revision_pb<T>(revisions: Vec<RevisionPB>) -> CollaborateResult<Delta<T>>
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

pub fn repeated_revision_from_revision_pbs(revisions: Vec<RevisionPB>) -> CollaborateResult<RepeatedRevision> {
    let repeated_revision_pb = repeated_revision_pb_from_revisions(revisions);
    repeated_revision_from_repeated_revision_pb(repeated_revision_pb)
}

pub fn repeated_revision_pb_from_revisions(revisions: Vec<RevisionPB>) -> RepeatedRevisionPB {
    let mut repeated_revision_pb = RepeatedRevisionPB::new();
    repeated_revision_pb.set_items(revisions.into());
    repeated_revision_pb
}

pub fn repeated_revision_from_repeated_revision_pb(
    repeated_revision: RepeatedRevisionPB,
) -> CollaborateResult<RepeatedRevision> {
    repeated_revision
        .try_into()
        .map_err(|e| CollaborateError::internal().context(format!("Cast repeated revision failed: {:?}", e)))
}

pub fn pair_rev_id_from_revision_pbs(revisions: &[RevisionPB]) -> (i64, i64) {
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
    revisions: RepeatedRevisionPB,
) -> Result<Option<FolderInfo>, CollaborateError> {
    match make_folder_pb_from_revisions_pb(folder_id, revisions)? {
        None => Ok(None),
        Some(pb) => {
            let folder_info: FolderInfo = pb.try_into().map_err(|e| CollaborateError::internal().context(e))?;
            Ok(Some(folder_info))
        }
    }
}

#[inline]
pub fn make_folder_pb_from_revisions_pb(
    folder_id: &str,
    mut revisions: RepeatedRevisionPB,
) -> Result<Option<FolderInfoPB>, CollaborateError> {
    let revisions = revisions.take_items();
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

    let text = folder_delta.to_delta_json();
    let mut folder_info = FolderInfoPB::new();
    folder_info.set_folder_id(folder_id.to_owned());
    folder_info.set_text(text);
    folder_info.set_base_rev_id(base_rev_id);
    folder_info.set_rev_id(rev_id);
    Ok(Some(folder_info))
}

#[inline]
pub fn make_document_info_from_revisions_pb(
    doc_id: &str,
    revisions: RepeatedRevisionPB,
) -> Result<Option<BlockInfo>, CollaborateError> {
    match make_document_info_pb_from_revisions_pb(doc_id, revisions)? {
        None => Ok(None),
        Some(pb) => {
            let document_info: BlockInfo = pb.try_into().map_err(|e| {
                CollaborateError::internal().context(format!("Deserialize document info from pb failed: {}", e))
            })?;
            Ok(Some(document_info))
        }
    }
}

#[inline]
pub fn make_document_info_pb_from_revisions_pb(
    doc_id: &str,
    mut revisions: RepeatedRevisionPB,
) -> Result<Option<BlockInfoPB>, CollaborateError> {
    let revisions = revisions.take_items();
    if revisions.is_empty() {
        return Ok(None);
    }

    let mut document_delta = RichTextDelta::new();
    let mut base_rev_id = 0;
    let mut rev_id = 0;
    for revision in revisions {
        base_rev_id = revision.base_rev_id;
        rev_id = revision.rev_id;

        if revision.delta_data.is_empty() {
            tracing::warn!("revision delta_data is empty");
        }

        let delta = RichTextDelta::from_bytes(revision.delta_data)?;
        document_delta = document_delta.compose(&delta)?;
    }

    let text = document_delta.to_delta_json();
    let mut block_info = BlockInfoPB::new();
    block_info.set_doc_id(doc_id.to_owned());
    block_info.set_text(text);
    block_info.set_base_rev_id(base_rev_id);
    block_info.set_rev_id(rev_id);
    Ok(Some(block_info))
}

#[inline]
pub fn rev_id_from_str(s: &str) -> Result<i64, CollaborateError> {
    let rev_id = s
        .to_owned()
        .parse::<i64>()
        .map_err(|e| CollaborateError::internal().context(format!("Parse rev_id from {} failed. {}", s, e)))?;
    Ok(rev_id)
}
