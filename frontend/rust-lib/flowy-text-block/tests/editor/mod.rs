#![allow(clippy::module_inception)]
mod attribute_test;
mod op_test;
mod serde_test;
mod undo_redo_test;

use derive_more::Display;
use flowy_sync::client_document::{ClientDocument, InitialDocumentText};
use lib_ot::{
    core::*,
    rich_text::{RichTextAttribute, RichTextAttributes, RichTextDelta},
};
use rand::{prelude::*, Rng as WrappedRng};
use std::{sync::Once, time::Duration};

const LEVEL: &str = "info";

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

    #[display(fmt = "Replace")]
    Replace(usize, Interval, &'static str),

    #[display(fmt = "Italic")]
    Italic(usize, Interval, bool),

    #[display(fmt = "Header")]
    Header(usize, Interval, usize),

    #[display(fmt = "Link")]
    Link(usize, Interval, &'static str),

    #[display(fmt = "Bullet")]
    Bullet(usize, Interval, bool),

    #[display(fmt = "Transform")]
    Transform(usize, usize),

    #[display(fmt = "TransformPrime")]
    TransformPrime(usize, usize),

    // invert the delta_a base on the delta_b
    #[display(fmt = "Invert")]
    Invert(usize, usize),

    #[display(fmt = "Undo")]
    Undo(usize),

    #[display(fmt = "Redo")]
    Redo(usize),

    #[display(fmt = "Wait")]
    Wait(usize),

    #[display(fmt = "AssertStr")]
    AssertStr(usize, &'static str),

    #[display(fmt = "AssertDocJson")]
    AssertDocJson(usize, &'static str),

    #[display(fmt = "AssertPrimeJson")]
    AssertPrimeJson(usize, &'static str),

    #[display(fmt = "DocComposeDelta")]
    DocComposeDelta(usize, usize),

    #[display(fmt = "ApplyPrimeDelta")]
    DocComposePrime(usize, usize),
}

pub struct TestBuilder {
    documents: Vec<ClientDocument>,
    deltas: Vec<Option<RichTextDelta>>,
    primes: Vec<Option<RichTextDelta>>,
}

impl TestBuilder {
    pub fn new() -> Self {
        static INIT: Once = Once::new();
        INIT.call_once(|| {
            let _ = color_eyre::install();
            std::env::set_var("RUST_LOG", LEVEL);
        });

        Self {
            documents: vec![],
            deltas: vec![],
            primes: vec![],
        }
    }

    fn run_op(&mut self, op: &TestOp) {
        tracing::trace!("***************** 😈{} *******************", &op);
        match op {
            TestOp::Insert(delta_i, s, index) => {
                let document = &mut self.documents[*delta_i];
                let delta = document.insert(*index, s).unwrap();
                tracing::debug!("Insert delta: {}", delta.to_delta_str());

                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::Delete(delta_i, iv) => {
                let document = &mut self.documents[*delta_i];
                let delta = document.replace(*iv, "").unwrap();
                tracing::trace!("Delete delta: {}", delta.to_delta_str());
                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::Replace(delta_i, iv, s) => {
                let document = &mut self.documents[*delta_i];
                let delta = document.replace(*iv, s).unwrap();
                tracing::trace!("Replace delta: {}", delta.to_delta_str());
                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::InsertBold(delta_i, s, iv) => {
                let document = &mut self.documents[*delta_i];
                document.insert(iv.start, s).unwrap();
                document.format(*iv, RichTextAttribute::Bold(true)).unwrap();
            }
            TestOp::Bold(delta_i, iv, enable) => {
                let document = &mut self.documents[*delta_i];
                let attribute = RichTextAttribute::Bold(*enable);
                let delta = document.format(*iv, attribute).unwrap();
                tracing::trace!("Bold delta: {}", delta.to_delta_str());
                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::Italic(delta_i, iv, enable) => {
                let document = &mut self.documents[*delta_i];
                let attribute = match *enable {
                    true => RichTextAttribute::Italic(true),
                    false => RichTextAttribute::Italic(false),
                };
                let delta = document.format(*iv, attribute).unwrap();
                tracing::trace!("Italic delta: {}", delta.to_delta_str());
                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::Header(delta_i, iv, level) => {
                let document = &mut self.documents[*delta_i];
                let attribute = RichTextAttribute::Header(*level);
                let delta = document.format(*iv, attribute).unwrap();
                tracing::trace!("Header delta: {}", delta.to_delta_str());
                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::Link(delta_i, iv, link) => {
                let document = &mut self.documents[*delta_i];
                let attribute = RichTextAttribute::Link(link.to_owned());
                let delta = document.format(*iv, attribute).unwrap();
                tracing::trace!("Link delta: {}", delta.to_delta_str());
                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::Bullet(delta_i, iv, enable) => {
                let document = &mut self.documents[*delta_i];
                let attribute = RichTextAttribute::Bullet(*enable);
                let delta = document.format(*iv, attribute).unwrap();
                tracing::debug!("Bullet delta: {}", delta.to_delta_str());

                self.deltas.insert(*delta_i, Some(delta));
            }
            TestOp::Transform(delta_a_i, delta_b_i) => {
                let (a_prime, b_prime) = self.documents[*delta_a_i]
                    .delta()
                    .transform(self.documents[*delta_b_i].delta())
                    .unwrap();
                tracing::trace!("a:{:?},b:{:?}", a_prime, b_prime);

                let data_left = self.documents[*delta_a_i].delta().compose(&b_prime).unwrap();
                let data_right = self.documents[*delta_b_i].delta().compose(&a_prime).unwrap();

                self.documents[*delta_a_i].set_delta(data_left);
                self.documents[*delta_b_i].set_delta(data_right);
            }
            TestOp::TransformPrime(a_doc_index, b_doc_index) => {
                let (prime_left, prime_right) = self.documents[*a_doc_index]
                    .delta()
                    .transform(self.documents[*b_doc_index].delta())
                    .unwrap();

                self.primes.insert(*a_doc_index, Some(prime_left));
                self.primes.insert(*b_doc_index, Some(prime_right));
            }
            TestOp::Invert(delta_a_i, delta_b_i) => {
                let delta_a = &self.documents[*delta_a_i].delta();
                let delta_b = &self.documents[*delta_b_i].delta();
                tracing::debug!("Invert: ");
                tracing::debug!("a: {}", delta_a.to_delta_str());
                tracing::debug!("b: {}", delta_b.to_delta_str());

                let (_, b_prime) = delta_a.transform(delta_b).unwrap();
                let undo = b_prime.invert(delta_a);

                let new_delta = delta_a.compose(&b_prime).unwrap();
                tracing::debug!("new delta: {}", new_delta.to_delta_str());
                tracing::debug!("undo delta: {}", undo.to_delta_str());

                let new_delta_after_undo = new_delta.compose(&undo).unwrap();

                tracing::debug!("inverted delta a: {}", new_delta_after_undo.to_string());

                assert_eq!(delta_a, &&new_delta_after_undo);

                self.documents[*delta_a_i].set_delta(new_delta_after_undo);
            }
            TestOp::Undo(delta_i) => {
                self.documents[*delta_i].undo().unwrap();
            }
            TestOp::Redo(delta_i) => {
                self.documents[*delta_i].redo().unwrap();
            }
            TestOp::Wait(mills_sec) => {
                std::thread::sleep(Duration::from_millis(*mills_sec as u64));
            }
            TestOp::AssertStr(delta_i, expected) => {
                assert_eq!(&self.documents[*delta_i].to_plain_string(), expected);
            }

            TestOp::AssertDocJson(delta_i, expected) => {
                let delta_json = self.documents[*delta_i].delta_str();
                let expected_delta: RichTextDelta = serde_json::from_str(expected).unwrap();
                let target_delta: RichTextDelta = serde_json::from_str(&delta_json).unwrap();

                if expected_delta != target_delta {
                    log::error!("✅ expect: {}", expected,);
                    log::error!("❌ receive: {}", delta_json);
                }
                assert_eq!(target_delta, expected_delta);
            }

            TestOp::AssertPrimeJson(doc_i, expected) => {
                let prime_json = self.primes[*doc_i].as_ref().unwrap().to_delta_str();
                let expected_prime: RichTextDelta = serde_json::from_str(expected).unwrap();
                let target_prime: RichTextDelta = serde_json::from_str(&prime_json).unwrap();

                if expected_prime != target_prime {
                    log::error!("✅ expect prime: {}", expected,);
                    log::error!("❌ receive prime: {}", prime_json);
                }
                assert_eq!(target_prime, expected_prime);
            }
            TestOp::DocComposeDelta(doc_index, delta_i) => {
                let delta = self.deltas.get(*delta_i).unwrap().as_ref().unwrap();
                self.documents[*doc_index].compose_delta(delta.clone()).unwrap();
            }
            TestOp::DocComposePrime(doc_index, prime_i) => {
                let delta = self
                    .primes
                    .get(*prime_i)
                    .expect("Must call TransformPrime first")
                    .as_ref()
                    .unwrap();
                let new_delta = self.documents[*doc_index].delta().compose(delta).unwrap();
                self.documents[*doc_index].set_delta(new_delta);
            }
        }
    }

    pub fn run_scripts<C: InitialDocumentText>(mut self, scripts: Vec<TestOp>) {
        self.documents = vec![ClientDocument::new::<C>(), ClientDocument::new::<C>()];
        self.primes = vec![None, None];
        self.deltas = vec![None, None];
        for (_i, op) in scripts.iter().enumerate() {
            self.run_op(op);
        }
    }
}

pub struct Rng(StdRng);

impl Default for Rng {
    fn default() -> Self {
        Rng(StdRng::from_rng(thread_rng()).unwrap())
    }
}

impl Rng {
    #[allow(dead_code)]
    pub fn from_seed(seed: [u8; 32]) -> Self {
        Rng(StdRng::from_seed(seed))
    }

    pub fn gen_string(&mut self, len: usize) -> String {
        (0..len)
            .map(|_| {
                let c = self.0.gen::<char>();
                format!("{:x}", c as u32)
            })
            .collect()
    }

    pub fn gen_delta(&mut self, s: &str) -> RichTextDelta {
        let mut delta = RichTextDelta::default();
        let s = FlowyStr::from(s);
        loop {
            let left = s.utf16_size() - delta.utf16_base_len;
            if left == 0 {
                break;
            }
            let i = if left == 1 {
                1
            } else {
                1 + self.0.gen_range(0..std::cmp::min(left - 1, 20))
            };
            match self.0.gen_range(0.0..1.0) {
                f if f < 0.2 => {
                    delta.insert(&self.gen_string(i), RichTextAttributes::default());
                }
                f if f < 0.4 => {
                    delta.delete(i);
                }
                _ => {
                    delta.retain(i, RichTextAttributes::default());
                }
            }
        }
        if self.0.gen_range(0.0..1.0) < 0.3 {
            delta.insert(&("1".to_owned() + &self.gen_string(10)), RichTextAttributes::default());
        }
        delta
    }
}
