use std::{fmt::Debug, marker::PhantomData};

pub trait Build<C> {
    fn build(code: C, msg: String) -> Self;
}
#[allow(dead_code)]
pub struct Builder<C, O> {
    pub code: C,
    pub msg: Option<String>,
    phantom: PhantomData<O>,
}

impl<C, O> Builder<C, O>
where
    C: Debug,
    O: Build<C> + Build<C>,
{
    pub fn new(code: C) -> Self {
        Builder {
            code,
            msg: None,
            phantom: PhantomData,
        }
    }

    pub fn msg<M>(mut self, msg: M) -> Self
    where
        M: Into<String>,
    {
        self.msg = Some(msg.into());
        self
    }

    pub fn error<Err>(mut self, err: Err) -> Self
    where
        Err: std::fmt::Debug,
    {
        self.msg = Some(format!("{:?}", err));
        self
    }

    pub fn build(mut self) -> O {
        let msg = self.msg.take().unwrap_or("".to_owned());
        O::build(self.code, msg)
    }
}
