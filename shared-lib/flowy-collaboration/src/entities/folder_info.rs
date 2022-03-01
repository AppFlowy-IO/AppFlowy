use flowy_derive::ProtoBuf;
use lib_ot::core::PlainTextDelta;

pub type FolderDelta = PlainTextDelta;

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct FolderInfo {
    #[pb(index = 1)]
    pub folder_id: String,

    #[pb(index = 2)]
    pub text: String,

    #[pb(index = 3)]
    pub rev_id: i64,

    #[pb(index = 4)]
    pub base_rev_id: i64,
}
