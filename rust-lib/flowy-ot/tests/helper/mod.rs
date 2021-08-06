use derive_more::Display;
use flowy_ot::{client::Document, core::*};
use rand::{prelude::*, Rng as WrappedRng};
use std::sync::Once;

#[derive(Clone, Debug, Display)]
pub enum TestOp {
    #[display(fmt = "Insert")]
    Insert(usize, &'static str, usize),

    // delta_i, s, start, length,
    #[display(fmt = "InsertBold")]
    InsertBold(usize, &'static str, Interval),

    // delta_i, start, length, enable
    #[display(fmt = "Bold")]
    Bold(usize, Interval, bool),

    #[display(fmt = "Delete")]
    Delete(usize, Interval),

    #[display(fmt = "Italic")]
    Italic(usize, Interval, bool),

    #[display(fmt = "Transform")]
    Transform(usize, usize),

    // invert the delta_a base on the delta_b
    #[display(fmt = "Invert")]
    Invert(usize, usize),

    #[display(fmt = "Undo")]
    Undo(usize),

    #[display(fmt = "Redo")]
    Redo(usize),

    #[display(fmt = "AssertStr")]
    AssertStr(usize, &'static str),

    #[display(fmt = "AssertOpsJson")]
    AssertOpsJson(usize, &'static str),
}

pub struct OpTester {
    documents: Vec<Document>,
}

impl OpTester {
    pub fn new() -> Self {
        static INIT: Once = Once::new();
        INIT.call_once(|| {
            std::env::set_var("RUST_LOG", "info");
            env_logger::init();
        });

        let mut documents = Vec::with_capacity(2);
        for _ in 0..2 {
            documents.push(Document::new());
        }
        Self { documents }
    }

    pub fn run_op(&mut self, op: &TestOp) {
        log::debug!("***************** 😈{} *******************", &op);
        match op {
            TestOp::Insert(delta_i, s, index) => {
                let document = &mut self.documents[*delta_i];
                document.edit(*index, s).unwrap();
            },
            TestOp::Delete(delta_i, interval) => {
                let document = &mut self.documents[*delta_i];
                document.delete(*interval).unwrap();
            },
            TestOp::InsertBold(delta_i, s, interval) => {
                let document = &mut self.documents[*delta_i];
                document.edit(interval.start, s).unwrap();
                document.format(*interval, Attribute::Bold, true).unwrap();
            },
            TestOp::Bold(delta_i, interval, enable) => {
                let document = &mut self.documents[*delta_i];
                document
                    .format(*interval, Attribute::Bold, *enable)
                    .unwrap();
            },
            TestOp::Italic(delta_i, interval, enable) => {
                let document = &mut self.documents[*delta_i];
                document
                    .format(*interval, Attribute::Italic, *enable)
                    .unwrap();
            },
            TestOp::Transform(delta_a_i, delta_b_i) => {
                let (a_prime, b_prime) = self.documents[*delta_a_i]
                    .data()
                    .transform(&self.documents[*delta_b_i].data())
                    .unwrap();
                log::trace!("a:{:?},b:{:?}", a_prime, b_prime);

                let data_left = self.documents[*delta_a_i].data().compose(&b_prime).unwrap();
                let data_right = self.documents[*delta_b_i].data().compose(&a_prime).unwrap();

                self.documents[*delta_a_i].set_data(data_left);
                self.documents[*delta_b_i].set_data(data_right);
            },
            TestOp::Invert(delta_a_i, delta_b_i) => {
                let delta_a = &self.documents[*delta_a_i].data();
                let delta_b = &self.documents[*delta_b_i].data();
                log::debug!("Invert: ");
                log::debug!("a: {}", delta_a.to_json());
                log::debug!("b: {}", delta_b.to_json());

                let (_, b_prime) = delta_a.transform(delta_b).unwrap();
                let undo = b_prime.invert(&delta_a);

                let new_delta = delta_a.compose(&b_prime).unwrap();
                log::debug!("new delta: {}", new_delta.to_json());
                log::debug!("undo delta: {}", undo.to_json());

                let new_delta_after_undo = new_delta.compose(&undo).unwrap();

                log::debug!("inverted delta a: {}", new_delta_after_undo.to_string());

                assert_eq!(delta_a, &&new_delta_after_undo);

                self.documents[*delta_a_i].set_data(new_delta_after_undo);
            },
            TestOp::Undo(delta_i) => {
                self.documents[*delta_i].undo().unwrap();
            },
            TestOp::Redo(delta_i) => {
                self.documents[*delta_i].redo().unwrap();
            },
            TestOp::AssertStr(delta_i, expected) => {
                assert_eq!(&self.documents[*delta_i].to_string(), expected);
            },

            TestOp::AssertOpsJson(delta_i, expected) => {
                let delta_i_json = self.documents[*delta_i].to_json();

                let expected_delta: Delta = serde_json::from_str(expected).unwrap();
                let target_delta: Delta = serde_json::from_str(&delta_i_json).unwrap();

                if expected_delta != target_delta {
                    log::error!("✅ expect: {}", expected,);
                    log::error!("❌ receive: {}", delta_i_json);
                }
                assert_eq!(target_delta, expected_delta);
            },
        }
    }

    pub fn run_script(&mut self, script: Vec<TestOp>) {
        for (_i, op) in script.iter().enumerate() {
            self.run_op(op);
        }
    }
}

pub fn debug_print_delta(delta: &Delta) {
    eprintln!("😁 {}", serde_json::to_string(delta).unwrap());
}

pub struct Rng(StdRng);

impl Default for Rng {
    fn default() -> Self { Rng(StdRng::from_rng(thread_rng()).unwrap()) }
}

impl Rng {
    pub fn from_seed(seed: [u8; 32]) -> Self { Rng(StdRng::from_seed(seed)) }

    pub fn gen_string(&mut self, len: usize) -> String {
        (0..len).map(|_| self.0.gen::<char>()).collect()
    }

    pub fn gen_delta(&mut self, s: &str) -> Delta {
        let mut delta = Delta::default();
        loop {
            let left = s.chars().count() - delta.base_len;
            if left == 0 {
                break;
            }
            let i = if left == 1 {
                1
            } else {
                1 + self.0.gen_range(0, std::cmp::min(left - 1, 20))
            };
            match self.0.gen_range(0.0, 1.0) {
                f if f < 0.2 => {
                    delta.insert(&self.gen_string(i), Attributes::Empty);
                },
                f if f < 0.4 => {
                    delta.delete(i as u64);
                },
                _ => {
                    delta.retain(i as u64, Attributes::Empty);
                },
            }
        }
        if self.0.gen_range(0.0, 1.0) < 0.3 {
            delta.insert(&("1".to_owned() + &self.gen_string(10)), Attributes::Empty);
        }
        delta
    }
}
