use crate::errors::UserError;
use flowy_dispatch::prelude::DispatchFuture;

pub trait UserWorkspaceController {
    fn create_workspace(
        &self,
        name: &str,
        desc: &str,
        user_id: &str,
    ) -> DispatchFuture<Result<String, UserError>>;
}
