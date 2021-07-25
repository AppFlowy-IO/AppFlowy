use crate::{
    entities::parser::*,
    errors::{ErrorBuilder, UserErrCode, UserError},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct UpdateUserRequest {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub email: Option<String>,

    #[pb(index = 4, one_of)]
    pub workspace: Option<String>,

    #[pb(index = 5, one_of)]
    pub password: Option<String>,
}

impl UpdateUserRequest {
    pub fn new(id: &str) -> Self {
        Self {
            id: id.to_owned(),
            ..Default::default()
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.name = Some(name.to_owned());
        self
    }

    pub fn email(mut self, email: &str) -> Self {
        self.email = Some(email.to_owned());
        self
    }

    pub fn workspace(mut self, workspace: &str) -> Self {
        self.workspace = Some(workspace.to_owned());
        self
    }

    pub fn password(mut self, password: &str) -> Self {
        self.password = Some(password.to_owned());
        self
    }
}

pub struct UpdateUserParams {
    pub id: String,
    pub name: Option<String>,
    pub email: Option<String>,
    pub workspace: Option<String>,
    pub password: Option<String>,
}

impl TryInto<UpdateUserParams> for UpdateUserRequest {
    type Error = UserError;

    fn try_into(self) -> Result<UpdateUserParams, Self::Error> {
        let id = UserId::parse(self.id)
            .map_err(|e| ErrorBuilder::new(UserErrCode::UserIdInvalid).msg(e).build())?
            .0;

        let name = match self.name {
            None => None,
            Some(name) => Some(
                UserName::parse(name)
                    .map_err(|e| {
                        ErrorBuilder::new(UserErrCode::UserNameInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let email = match self.email {
            None => None,
            Some(email) => Some(
                UserEmail::parse(email)
                    .map_err(|e| ErrorBuilder::new(UserErrCode::EmailInvalid).msg(e).build())?
                    .0,
            ),
        };

        let workspace = match self.workspace {
            None => None,
            Some(workspace) => Some(
                UserWorkspace::parse(workspace)
                    .map_err(|e| {
                        ErrorBuilder::new(UserErrCode::UserWorkspaceInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let password = match self.password {
            None => None,
            Some(password) => Some(
                UserPassword::parse(password)
                    .map_err(|e| {
                        ErrorBuilder::new(UserErrCode::PasswordInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        Ok(UpdateUserParams {
            id,
            name,
            email,
            workspace,
            password,
        })
    }
}
