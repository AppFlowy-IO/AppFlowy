use crate::{
    entities::revision::{RepeatedRevision, Revision},
    errors::{CollaborateError, CollaborateResult},
    protobuf::{RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB},
};
use lib_ot::{
    core::{OperationTransformable, NEW_LINE, WHITESPACE},
    rich_text::RichTextDelta,
};
use std::{
    convert::TryInto,
    sync::atomic::{AtomicI64, Ordering::SeqCst},
};

#[inline]
pub fn find_newline(s: &str) -> Option<usize> { s.find(NEW_LINE) }

#[inline]
pub fn is_newline(s: &str) -> bool { s == NEW_LINE }

#[inline]
pub fn is_whitespace(s: &str) -> bool { s == WHITESPACE }

#[inline]
pub fn contain_newline(s: &str) -> bool { s.contains(NEW_LINE) }

#[inline]
pub fn md5<T: AsRef<[u8]>>(data: T) -> String {
    let md5 = format!("{:x}", md5::compute(data));
    md5
}

#[derive(Debug)]
pub struct RevIdCounter(pub AtomicI64);

impl RevIdCounter {
    pub fn new(n: i64) -> Self { Self(AtomicI64::new(n)) }
    pub fn next(&self) -> i64 {
        let _ = self.0.fetch_add(1, SeqCst);
        self.value()
    }
    pub fn value(&self) -> i64 { self.0.load(SeqCst) }

    pub fn set(&self, n: i64) { let _ = self.0.fetch_update(SeqCst, SeqCst, |_| Some(n)); }
}

pub fn make_delta_from_revisions(revisions: Vec<Revision>) -> CollaborateResult<RichTextDelta> {
    let mut new_delta = RichTextDelta::new();
    for revision in revisions {
        let delta = RichTextDelta::from_bytes(revision.delta_data).map_err(|e| {
            let err_msg = format!("Deserialize remote revision failed: {:?}", e);
            CollaborateError::internal().context(err_msg)
        })?;
        new_delta = new_delta.compose(&delta)?;
    }
    Ok(new_delta)
}

pub fn make_delta_from_revision_pb(revisions: Vec<RevisionPB>) -> CollaborateResult<RichTextDelta> {
    let mut new_delta = RichTextDelta::new();
    for revision in revisions {
        let delta = RichTextDelta::from_bytes(revision.delta_data).map_err(|e| {
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
    mut repeated_revision: RepeatedRevisionPB,
) -> CollaborateResult<RepeatedRevision> {
    (&mut repeated_revision)
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
