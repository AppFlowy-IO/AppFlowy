use collab_folder::core::FavoritesInfo;
use flowy_derive::ProtoBuf;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct FavoritesPB {
  #[pb(index = 1)]
  pub id: String,
}

impl std::convert::From<FavoritesInfo> for FavoritesPB {
  fn from(favorite_info: FavoritesInfo) -> Self {
    FavoritesPB {
      id: favorite_info.id,
    }
  }
}

impl AsRef<str> for FavoritesPB {
  fn as_ref(&self) -> &str {
    &self.id
  }
}

impl std::convert::From<FavoritesPB> for FavoritesInfo {
  fn from(favorite: FavoritesPB) -> Self {
    FavoritesInfo { id: favorite.id }
  }
}
#[derive(PartialEq, Eq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedFavoritesPB {
  #[pb(index = 1)]
  pub items: Vec<FavoritesPB>,
}

impl std::convert::From<Vec<FavoritesInfo>> for RepeatedFavoritesPB {
  fn from(favorite_vector: Vec<FavoritesInfo>) -> Self {
    let items: Vec<FavoritesPB> = favorite_vector
      .into_iter()
      .map(|favorite_info| favorite_info.into())
      .collect();
    RepeatedFavoritesPB { items }
  }
}
