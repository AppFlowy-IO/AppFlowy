use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default, Debug)]
pub struct CurrentWorkspace {
    #[pb(index = 1)]
    pub workspace_id: String,
}
