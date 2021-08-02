use flowy_ot::{
    attributes::{Attributes, AttrsBuilder},
    delta::Delta,
    interval::Interval,
    operation::{OpBuilder, Operation},
};
use rand::{prelude::*, Rng as WrappedRng};
use std::sync::Once;

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
            let left = s.chars().count() - delta.base_len();
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
                    delta.insert(&self.gen_string(i), None);
                },
                f if f < 0.4 => {
                    delta.delete(i as u64);
                },
                _ => {
                    delta.retain(i as u64, None);
                },
            }
        }
        if self.0.gen_range(0.0, 1.0) < 0.3 {
            delta.insert(&("1".to_owned() + &self.gen_string(10)), None);
        }
        delta
    }
}

#[derive(Clone, Debug)]
pub enum MergeTestOp {
    Insert(usize, &'static str),
    // delta_i, s, start, length,
    InsertBold(usize, &'static str, Interval),
    // delta_i, start, length, enable
    Bold(usize, Interval, bool),
    Transform(usize, usize),
    AssertStr(usize, &'static str),
    AssertOpsJson(usize, &'static str),
}

pub struct MergeTest {
    deltas: Vec<Delta>,
}

impl MergeTest {
    pub fn new() -> Self {
        static INIT: Once = Once::new();
        INIT.call_once(|| {
            std::env::set_var("RUST_LOG", "debug");
            env_logger::init();
        });

        let mut deltas = Vec::with_capacity(2);
        for _ in 0..2 {
            let delta = Delta::default();
            deltas.push(delta);
        }
        Self { deltas }
    }

    pub fn run_op(&mut self, op: &MergeTestOp) {
        match op {
            MergeTestOp::Insert(delta_i, s) => {
                let delta = &mut self.deltas[*delta_i];
                delta.insert(s, None);
            },
            MergeTestOp::InsertBold(delta_i, s, interval) => {
                let attrs = AttrsBuilder::new().bold().build();
                let delta = &mut self.deltas[*delta_i];
                delta.insert(s, Some(attrs));
            },
            MergeTestOp::Bold(delta_i, interval, enable) => {
                let attrs = if *enable {
                    AttrsBuilder::new().bold().build()
                } else {
                    AttrsBuilder::new().un_bold().build()
                };
                let delta = &mut self.deltas[*delta_i];
                let delta_interval = Interval::new(0, delta.target_len);

                let mut new_delta = Delta::default();
                let prefix = delta_interval.prefix(*interval);
                if prefix.is_empty() == false && prefix != *interval {
                    let size = prefix.size();
                    // get attr in prefix interval
                    let attrs = attributes_in_interval(delta, &prefix);
                    new_delta.retain(size as u64, Some(attrs));
                }

                let size = interval.size();
                new_delta.retain(size as u64, Some(attrs));

                let suffix = delta_interval.suffix(*interval);
                if suffix.is_empty() == false {
                    let size = suffix.size();
                    let attrs = attributes_in_interval(delta, &suffix);
                    new_delta.retain(size as u64, Some(attrs));
                }

                let a = delta.compose(&new_delta).unwrap();
                self.deltas[*delta_i] = a;
            },
            MergeTestOp::Transform(delta_a_i, delta_b_i) => {
                let delta_a = &self.deltas[*delta_a_i];
                let delta_b = &self.deltas[*delta_b_i];

                let (a_prime, b_prime) = delta_a.transform(delta_b).unwrap();
                let new_delta_a = delta_a.compose(&b_prime).unwrap();
                let new_delta_b = delta_b.compose(&a_prime).unwrap();

                self.deltas[*delta_a_i] = new_delta_a;
                self.deltas[*delta_b_i] = new_delta_b;
            },
            MergeTestOp::AssertStr(delta_i, expected) => {
                let s = self.deltas[*delta_i].apply("").unwrap();
                assert_eq!(&s, expected);
            },

            MergeTestOp::AssertOpsJson(delta_i, expected) => {
                let s = serde_json::to_string(&self.deltas[*delta_i]).unwrap();
                if &s != expected {
                    log::error!("{}", s);
                }

                assert_eq!(&s, expected);
            },
        }
    }

    pub fn run_script(&mut self, script: Vec<MergeTestOp>) {
        for (i, op) in script.iter().enumerate() {
            self.run_op(op);
        }
    }
}

pub fn debug_print_delta(delta: &Delta) {
    log::debug!("😁 {}", serde_json::to_string(delta).unwrap());
}

pub fn attributes_in_interval(delta: &Delta, interval: &Interval) -> Attributes {
    let mut attributes = Attributes::new();
    let mut offset = 0;

    delta.ops.iter().for_each(|op| match op {
        Operation::Delete(n) => {},
        Operation::Retain(retain) => {
            if retain.attributes.is_some() {
                if interval.contains(retain.num as usize) {
                    attributes.extend(retain.attributes.as_ref().unwrap().clone());
                }
            }
        },
        Operation::Insert(insert) => {
            if insert.attributes.is_some() {
                if interval.start >= offset || insert.num_chars() > interval.end as u64 {
                    attributes.extend(insert.attributes.as_ref().unwrap().clone());
                }
                offset += insert.num_chars() as usize;
            }
        },
    });
    attributes
}
