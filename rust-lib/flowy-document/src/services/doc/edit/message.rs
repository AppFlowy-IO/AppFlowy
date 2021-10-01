use crate::{
    errors::DocResult,
    services::doc::{edit::DocId, Document, UndoResult},
    sql_tables::{DocTableChangeset, DocTableSql},
};
use flowy_ot::core::{Attribute, Delta, Interval};

use tokio::sync::oneshot;
pub type Ret<T> = oneshot::Sender<DocResult<T>>;
pub enum EditMsg {
    Delta {
        delta: Delta,
        ret: Ret<()>,
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
    SaveRevision {
        rev_id: i64,
        ret: Ret<()>,
    },
}
