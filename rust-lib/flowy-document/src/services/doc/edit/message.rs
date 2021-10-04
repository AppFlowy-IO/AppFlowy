use crate::{errors::DocResult, services::doc::UndoResult};
use flowy_ot::core::{Attribute, Delta, Interval};

use crate::entities::doc::{RevId, Revision};
use bytes::Bytes;
use tokio::sync::oneshot;

pub type Ret<T> = oneshot::Sender<DocResult<T>>;
pub enum EditMsg {
    Delta {
        delta: Delta,
        ret: Ret<()>,
    },
    RemoteRevision {
        bytes: Bytes,
        ret: Ret<TransformDeltas>,
    },
    Insert {
        index: usize,
        data: String,
        ret: Ret<Delta>,
    },
    Delete {
        interval: Interval,
        ret: Ret<Delta>,
    },
    Format {
        interval: Interval,
        attribute: Attribute,
        ret: Ret<Delta>,
    },

    Replace {
        interval: Interval,
        data: String,
        ret: Ret<Delta>,
    },
    CanUndo {
        ret: oneshot::Sender<bool>,
    },
    CanRedo {
        ret: oneshot::Sender<bool>,
    },
    Undo {
        ret: Ret<UndoResult>,
    },
    Redo {
        ret: Ret<UndoResult>,
    },
    Doc {
        ret: Ret<String>,
    },
    SaveDocument {
        rev_id: RevId,
        ret: Ret<()>,
    },
}

pub struct TransformDeltas {
    pub client_prime: Delta,
    pub server_prime: Delta,
    pub server_rev_id: RevId,
}
