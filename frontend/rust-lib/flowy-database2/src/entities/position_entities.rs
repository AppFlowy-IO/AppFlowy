use collab_database::views::OrderObjectPosition;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::entities::parser::NotEmptyStr;

#[derive(Debug, Default, ProtoBuf)]
pub struct OrderObjectPositionPB {
  #[pb(index = 1)]
  pub position: OrderObjectPositionTypePB,

  #[pb(index = 2, one_of)]
  pub object_id: Option<String>,
}

#[derive(Debug, Default, ProtoBuf_Enum)]
#[repr(u8)]
pub enum OrderObjectPositionTypePB {
  #[default]
  End = 0,
  Start = 1,
  Before = 2,
  After = 3,
}

impl TryFrom<OrderObjectPositionPB> for OrderObjectPosition {
  type Error = ErrorCode;

  fn try_from(value: OrderObjectPositionPB) -> Result<Self, Self::Error> {
    match value.position {
      OrderObjectPositionTypePB::Start => {
        if value.object_id.is_some() {
          return Err(ErrorCode::InvalidParams);
        }
        Ok(OrderObjectPosition::Start)
      },
      OrderObjectPositionTypePB::End => {
        if value.object_id.is_some() {
          return Err(ErrorCode::InvalidParams);
        }
        Ok(OrderObjectPosition::End)
      },
      OrderObjectPositionTypePB::Before => {
        let field_id = value.object_id.ok_or(ErrorCode::InvalidParams)?;
        let field_id = NotEmptyStr::parse(field_id)
          .map_err(|_| ErrorCode::InvalidParams)?
          .0;
        Ok(OrderObjectPosition::Before(field_id))
      },
      OrderObjectPositionTypePB::After => {
        let field_id = value.object_id.ok_or(ErrorCode::InvalidParams)?;
        let field_id = NotEmptyStr::parse(field_id)
          .map_err(|_| ErrorCode::InvalidParams)?
          .0;
        Ok(OrderObjectPosition::After(field_id))
      },
    }
  }
}
