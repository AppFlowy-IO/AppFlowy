use crate::request::FlowyRequest;
use crate::response::FlowyResponse;
use crate::response::FlowyResponseBuilder;

pub trait Responder {
    fn respond_to(self, req: &FlowyRequest) -> FlowyResponse;
}

macro_rules! impl_responder {
    ($res: ty) => {
        impl Responder for $res {
            fn respond_to(self, _: &FlowyRequest) -> FlowyResponse {
                FlowyResponseBuilder::Ok().data(self).build()
            }
        }
    };
}

impl_responder!(&'static str);
impl_responder!(String);
