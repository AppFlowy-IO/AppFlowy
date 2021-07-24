use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default, Debug)]
pub struct CurrentWorkspace {
    #[pb(index = 1)]
    pub owner: String,

    #[pb(index = 2)]
    pub workspace_id: String,
}
