use flowy_ot::{
    attributes::{Attributes, AttributesData, AttrsBuilder},
    delta::Delta,
    interval::Interval,
    operation::{OpBuilder, Operation},
};
use rand::{prelude::*, Rng as WrappedRng};
use std::sync::Once;

#[derive(Clone, Debug)]
pub enum MergeTestOp {
    Insert(usize, &'static str),
    // delta_i, s, start, length,
    InsertBold(usize, &'static str, Interval),
    // delta_i, start, length, enable
    Bold(usize, Interval, bool),
    Delete(usize, Interval),
    Italic(usize, Interval, bool),
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
            std::env::set_var("RUST_LOG", "info");
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
                delta.insert(s, Attributes::Follow);
            },
            MergeTestOp::Delete(delta_i, interval) => {
                //
                self.update_delta_with_delete(*delta_i, interval);
            },
            MergeTestOp::InsertBold(delta_i, s, _interval) => {
                let attrs = AttrsBuilder::new().bold(true).build();
                let delta = &mut self.deltas[*delta_i];
                delta.insert(s, attrs);
            },
            MergeTestOp::Bold(delta_i, interval, enable) => {
                let attrs = AttrsBuilder::new().bold(*enable).build();
                self.update_delta_with_attribute(*delta_i, attrs, interval);
            },
            MergeTestOp::Italic(delta_i, interval, enable) => {
                let attrs = AttrsBuilder::new().italic(*enable).build();
                self.update_delta_with_attribute(*delta_i, attrs, interval);
            },
            MergeTestOp::Transform(delta_a_i, delta_b_i) => {
                let delta_a = &self.deltas[*delta_a_i];
                let delta_b = &self.deltas[*delta_b_i];

                let (a_prime, b_prime) = delta_a.transform(delta_b).unwrap();
                log::trace!("a:{:?},b:{:?}", a_prime, b_prime);
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
                let delta_i_json = serde_json::to_string(&self.deltas[*delta_i]).unwrap();

                let expected_delta: Delta = serde_json::from_str(expected).unwrap();
                let target_delta: Delta = serde_json::from_str(&delta_i_json).unwrap();

                if expected_delta != target_delta {
                    log::error!("✅ {}", expected);
                    log::error!("❌ {}", delta_i_json);
                }
                assert_eq!(target_delta, expected_delta);
            },
        }
    }

    pub fn run_script(&mut self, script: Vec<MergeTestOp>) {
        for (_i, op) in script.iter().enumerate() {
            self.run_op(op);
        }
    }

    pub fn update_delta_with_attribute(
        &mut self,
        delta_index: usize,
        attributes: Attributes,
        interval: &Interval,
    ) {
        let old_delta = &self.deltas[delta_index];
        let retain = OpBuilder::retain(interval.size() as u64)
            .attributes(attributes)
            .build();
        let new_delta = make_delta_with_op(old_delta, retain, interval);
        self.deltas[delta_index] = new_delta;
    }

    pub fn update_delta_with_delete(&mut self, delta_index: usize, interval: &Interval) {
        let old_delta = &self.deltas[delta_index];
        let delete = OpBuilder::delete(interval.size() as u64).build();
        let new_delta = make_delta_with_op(old_delta, delete, interval);
        self.deltas[delta_index] = new_delta;
    }
}

pub fn make_delta_with_op(delta: &Delta, op: Operation, interval: &Interval) -> Delta {
    let mut new_delta = Delta::default();
    let (prefix, suffix) = length_split_with_interval(delta.target_len, interval);

    // prefix
    if prefix.is_empty() == false && prefix != *interval {
        let size = prefix.size();
        let attrs = attributes_in_interval(delta, &prefix);
        new_delta.retain(size as u64, attrs);
    }

    new_delta.add(op);

    // suffix
    if suffix.is_empty() == false {
        let size = suffix.size();
        let attrs = attributes_in_interval(delta, &suffix);
        new_delta.retain(size as u64, attrs);
    }

    delta.compose(&new_delta).unwrap()
}

pub fn length_split_with_interval(length: usize, interval: &Interval) -> (Interval, Interval) {
    let original_interval = Interval::new(0, length);
    let prefix = original_interval.prefix(*interval);
    let suffix = original_interval.suffix(*interval);
    (prefix, suffix)
}

pub fn debug_print_delta(delta: &Delta) {
    log::debug!("😁 {}", serde_json::to_string(delta).unwrap());
}

pub fn attributes_in_interval(delta: &Delta, interval: &Interval) -> Attributes {
    let mut attributes_data = AttributesData::new();
    let mut offset = 0;

    delta.ops.iter().for_each(|op| match op {
        Operation::Delete(_n) => {},
        Operation::Retain(retain) => {
            if interval.contains(retain.num as usize) {
                match &retain.attributes {
                    Attributes::Follow => {},
                    Attributes::Custom(data) => {
                        attributes_data.extend(data.clone());
                    },
                    Attributes::Empty => {},
                }
            }
        },
        Operation::Insert(insert) => match &insert.attributes {
            Attributes::Follow => {},
            Attributes::Custom(data) => {
                if interval.start >= offset && insert.num_chars() > (interval.end as u64 - 1) {
                    attributes_data.extend(data.clone());
                }
                offset += insert.num_chars() as usize;
            },
            Attributes::Empty => {},
        },
    });

    if attributes_data.is_plain() {
        Attributes::Empty
    } else {
        Attributes::Custom(attributes_data)
    }
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
