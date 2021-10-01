use crate::{
    errors::{internal_error, DocResult},
    services::doc::{edit::DocId, Document, UndoResult},
    sql_tables::{DocTableChangeset, DocTableSql},
};
use async_stream::stream;
use flowy_database::ConnectionPool;
use flowy_ot::core::{Attribute, Delta, Interval};
use futures::stream::StreamExt;
use std::{cell::RefCell, sync::Arc};
use tokio::sync::{mpsc, oneshot};

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

pub struct DocumentEditActor {
    doc_id: DocId,
    document: RefCell<Document>,
    pool: Arc<ConnectionPool>,
    receiver: Option<mpsc::UnboundedReceiver<EditMsg>>,
}

impl DocumentEditActor {
    pub fn new(
        doc_id: &str,
        delta: Delta,
        pool: Arc<ConnectionPool>,
        receiver: mpsc::UnboundedReceiver<EditMsg>,
    ) -> Self {
        let doc_id = doc_id.to_string();
        let document = RefCell::new(Document::from_delta(delta));
        Self {
            doc_id,
            document,
            pool,
            receiver: Some(receiver),
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.receiver.take().expect("Should only call once");
        let stream = stream! {
            loop {
                match receiver.recv().await {
                    Some(msg) => yield msg,
                    None => break,
                }
            }
        };
        stream.for_each(|msg| self.handle_message(msg)).await;
    }

    async fn handle_message(&self, msg: EditMsg) {
        match msg {
            EditMsg::Delta { delta, ret } => {
                let result = self.document.borrow_mut().compose_delta(&delta);
                let _ = ret.send(result);
            },
            EditMsg::Insert { index, data, ret } => {
                let delta = self.document.borrow_mut().insert(index, data);
                let _ = ret.send(delta);
            },
            EditMsg::Delete { interval, ret } => {
                let result = self.document.borrow_mut().delete(interval);
                let _ = ret.send(result);
            },
            EditMsg::Format {
                interval,
                attribute,
                ret,
            } => {
                let result = self.document.borrow_mut().format(interval, attribute);
                let _ = ret.send(result);
            },
            EditMsg::Replace { interval, data, ret } => {
                let result = self.document.borrow_mut().replace(interval, data);
                let _ = ret.send(result);
            },
            EditMsg::CanUndo { ret } => {
                let _ = ret.send(self.document.borrow().can_undo());
            },
            EditMsg::CanRedo { ret } => {
                let _ = ret.send(self.document.borrow().can_redo());
            },
            EditMsg::Undo { ret } => {
                let result = self.document.borrow_mut().undo();
                let _ = ret.send(result);
            },
            EditMsg::Redo { ret } => {
                let result = self.document.borrow_mut().redo();
                let _ = ret.send(result);
            },
            EditMsg::Doc { ret } => {
                let data = self.document.borrow().to_json();
                let _ = ret.send(Ok(data));
            },
            EditMsg::SaveRevision { rev_id, ret } => {
                let result = self.save_to_disk(rev_id);
                let _ = ret.send(result);
            },
        }
    }

    #[tracing::instrument(level = "debug", skip(self, rev_id), err)]
    fn save_to_disk(&self, rev_id: i64) -> DocResult<()> {
        let data = self.document.borrow().to_json();
        let changeset = DocTableChangeset {
            id: self.doc_id.clone(),
            data,
            rev_id,
        };
        let sql = DocTableSql {};
        let conn = self.pool.get().map_err(internal_error)?;
        let _ = sql.update_doc_table(changeset, &*conn)?;
        Ok(())
    }
}

// #[tracing::instrument(level = "debug", skip(self, params), err)]
// fn update_doc_on_server(&self, params: UpdateDocParams) -> Result<(),
//     DocError> {     let token = self.user.token()?;
//     let server = self.server.clone();
//     tokio::spawn(async move {
//         match server.update_doc(&token, params).await {
//             Ok(_) => {},
//             Err(e) => {
//                 // TODO: retry?
//                 log::error!("Update doc failed: {}", e);
//             },
//         }
//     });
//     Ok(())
// }
