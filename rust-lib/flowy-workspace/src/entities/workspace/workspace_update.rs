use std::convert::TryInto;

use flowy_derive::ProtoBuf;

use crate::{entities::workspace::parser::*, errors::*};

#[derive(ProtoBuf, Default)]
pub struct UpdateWorkspaceRequest {
    #[pb(index = 1)]
    id: String,

    #[pb(index = 2, one_of)]
    name: Option<String>,

    #[pb(index = 3, one_of)]
    desc: Option<String>,
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct UpdateWorkspaceParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,
}

impl TryInto<UpdateWorkspaceParams> for UpdateWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<UpdateWorkspaceParams, Self::Error> {
        let name = match self.name {
            None => None,
            Some(name) => Some(
                WorkspaceName::parse(name)
                    .map_err(|e| WorkspaceError::workspace_name().context(e))?
                    .0,
            ),
        };

        let id = WorkspaceId::parse(self.id).map_err(|e| WorkspaceError::workspace_id().context(e))?;

        Ok(UpdateWorkspaceParams {
            id: id.0,
            name,
            desc: self.desc,
        })
    }
}
