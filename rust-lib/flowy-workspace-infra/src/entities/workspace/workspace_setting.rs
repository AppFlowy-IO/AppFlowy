use crate::entities::{view::View, workspace::Workspace};
use flowy_derive::ProtoBuf;

#[derive(Default, ProtoBuf, Clone)]
pub struct CurrentWorkspaceSetting {
    #[pb(index = 1)]
    pub workspace: Workspace,

    #[pb(index = 2, one_of)]
    pub latest_view: Option<View>,
}
