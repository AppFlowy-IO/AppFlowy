use crate::{
    client::view::{InsertExt, PreserveInlineStyleExt},
    core::Delta,
};

type InsertExtension = Box<dyn InsertExt>;

pub struct View {
    insert_exts: Vec<InsertExtension>,
}

impl View {
    pub(crate) fn new() -> Self {
        let insert_exts = construct_insert_exts();
        Self { insert_exts }
    }

    pub(crate) fn handle_insert(&self, delta: &Delta, s: &str, index: usize) -> Delta {
        let mut new_delta = Delta::new();
        self.insert_exts.iter().for_each(|ext| {
            new_delta = ext.apply(delta, s, index);
        });
        new_delta
    }
}

fn construct_insert_exts() -> Vec<InsertExtension> {
    vec![
        //
        Box::new(PreserveInlineStyleExt::new()),
    ]
}
