use collab_folder::TrashInfo;
use flowy_derive::ProtoBuf;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct TrashPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub modified_time: i64,

  #[pb(index = 4)]
  pub create_time: i64,
}

impl std::convert::From<TrashInfo> for TrashPB {
  fn from(trash_info: TrashInfo) -> Self {
    TrashPB {
      id: trash_info.id,
      name: trash_info.name,
      modified_time: trash_info.created_at,
      create_time: trash_info.created_at,
    }
  }
}

impl std::convert::From<TrashPB> for TrashInfo {
  fn from(trash: TrashPB) -> Self {
    TrashInfo {
      id: trash.id,
      name: trash.name,
      created_at: trash.create_time,
    }
  }
}
#[derive(PartialEq, Eq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedTrashPB {
  #[pb(index = 1)]
  pub items: Vec<TrashPB>,
}

impl std::convert::From<Vec<TrashInfo>> for RepeatedTrashPB {
  fn from(trash_revs: Vec<TrashInfo>) -> Self {
    let items: Vec<TrashPB> = trash_revs
      .into_iter()
      .map(|trash_rev| trash_rev.into())
      .collect();
    RepeatedTrashPB { items }
  }
}

#[derive(PartialEq, Eq, ProtoBuf, Default, Debug, Clone)]
pub struct TrashIdPB {
  #[pb(index = 1)]
  pub id: String,
}

impl std::convert::From<&TrashInfo> for TrashIdPB {
  fn from(trash_info: &TrashInfo) -> Self {
    TrashIdPB {
      id: trash_info.id.clone(),
    }
  }
}

#[derive(PartialEq, Eq, ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedTrashIdPB {
  #[pb(index = 1)]
  pub items: Vec<TrashIdPB>,
}
