use flowy_derive::ProtoBuf;

#[derive(Debug, Clone, ProtoBuf)]
pub struct ObservableSubject {
    #[pb(index = 1)]
    pub category: String,

    #[pb(index = 2)]
    pub ty: i32,

    #[pb(index = 3)]
    pub subject_id: String,

    #[pb(index = 4, one_of)]
    pub subject_payload: Option<Vec<u8>>,
}

impl std::default::Default for ObservableSubject {
    fn default() -> Self {
        Self {
            ..Default::default()
        }
    }
}
