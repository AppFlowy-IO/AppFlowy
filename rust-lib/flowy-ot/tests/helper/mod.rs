use flowy_ot::core::*;
use rand::{prelude::*, Rng as WrappedRng};
use std::sync::Once;

#[derive(Clone, Debug)]
pub enum TestOp {
    Insert(usize, &'static str, usize),
    // delta_i, s, start, length,
    InsertBold(usize, &'static str, Interval),
    // delta_i, start, length, enable
    Bold(usize, Interval, bool),
    Delete(usize, Interval),
    Italic(usize, Interval, bool),
    Transform(usize, usize),
    // invert the delta_a base on the delta_b
    Invert(usize, usize),
    AssertStr(usize, &'static str),
    AssertOpsJson(usize, &'static str),
}

pub struct OpTester {
    deltas: Vec<Delta>,
}

impl OpTester {
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

    pub fn run_op(&mut self, op: &TestOp) {
        match op {
            TestOp::Insert(delta_i, s, index) => {
                self.update_delta_with_insert(*delta_i, s, *index);
            },
            TestOp::Delete(delta_i, interval) => {
                //
                self.update_delta_with_delete(*delta_i, interval);
            },
            TestOp::InsertBold(delta_i, s, _interval) => {
                let attrs = AttrsBuilder::new().bold(true).build();
                let delta = &mut self.deltas[*delta_i];
                delta.insert(s, attrs);
            },
            TestOp::Bold(delta_i, interval, enable) => {
                let attrs = AttrsBuilder::new().bold(*enable).build();
                self.update_delta_with_attribute(*delta_i, attrs, interval);
            },
            TestOp::Italic(delta_i, interval, enable) => {
                let attrs = AttrsBuilder::new().italic(*enable).build();
                self.update_delta_with_attribute(*delta_i, attrs, interval);
            },
            TestOp::Transform(delta_a_i, delta_b_i) => {
                let delta_a = &self.deltas[*delta_a_i];
                let delta_b = &self.deltas[*delta_b_i];

                let (a_prime, b_prime) = delta_a.transform(delta_b).unwrap();
                log::trace!("a:{:?},b:{:?}", a_prime, b_prime);
                let new_delta_a = delta_a.compose(&b_prime).unwrap();
                let new_delta_b = delta_b.compose(&a_prime).unwrap();

                self.deltas[*delta_a_i] = new_delta_a;
                self.deltas[*delta_b_i] = new_delta_b;
            },
            TestOp::Invert(delta_a_i, delta_b_i) => {
                let delta_a = &self.deltas[*delta_a_i];
                let delta_b = &self.deltas[*delta_b_i];

                let (_, b_prime) = delta_a.transform(delta_b).unwrap();
                let undo = b_prime.invert_delta(&delta_a);
                let new_delta = delta_a.compose(&b_prime).unwrap();
                let new_delta_after_undo = new_delta.compose(&undo).unwrap();

                assert_eq!(delta_a, &new_delta_after_undo);

                self.deltas[*delta_a_i] = new_delta_after_undo;
            },
            TestOp::AssertStr(delta_i, expected) => {
                let s = self.deltas[*delta_i].apply("").unwrap();
                assert_eq!(&s, expected);
            },

            TestOp::AssertOpsJson(delta_i, expected) => {
                log::debug!("AssertOpsJson: {:?}", self.deltas[*delta_i]);
                let delta_i_json = serde_json::to_string(&self.deltas[*delta_i]).unwrap();

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

    pub fn get_delta(&mut self, index: usize) -> &mut Delta { &mut self.deltas[index] }

    pub fn update_delta_with_insert(&mut self, delta_index: usize, s: &str, index: usize) {
        let old_delta = &mut self.deltas[delta_index];
        let target_interval = Interval::new(0, old_delta.target_len);
        if old_delta.target_len < index {
            log::error!("{} out of bounds {}", index, target_interval);
        }

        let mut attributes = old_delta.attributes_in_interval(Interval::new(index, index + 1));
        if attributes == Attributes::Empty {
            attributes = Attributes::Follow;
        }
        let insert = OpBuilder::insert(s).attributes(attributes).build();
        let new_delta = new_delta_with_op(old_delta, insert, Interval::new(index, index));
        self.deltas[delta_index] = new_delta;
    }

    pub fn update_delta_with_attribute(
        &mut self,
        delta_index: usize,
        mut attributes: Attributes,
        interval: &Interval,
    ) {
        let old_delta = &self.deltas[delta_index];
        let old_attributes = old_delta.attributes_in_interval(*interval);
        let new_attributes = match &mut attributes {
            Attributes::Follow => old_attributes,
            Attributes::Custom(attr_data) => {
                attr_data.merge(old_attributes.data());
                attr_data.clone().into_attributes()
            },
            Attributes::Empty => Attributes::Empty,
        };

        let retain = OpBuilder::retain(interval.size() as u64)
            .attributes(new_attributes)
            .build();

        log::debug!(
            "Update delta with attributes: {:?} at: {:?}",
            retain,
            interval
        );

        let new_delta = new_delta_with_op(old_delta, retain, *interval);
        self.deltas[delta_index] = new_delta;
    }

    pub fn update_delta_with_delete(&mut self, delta_index: usize, interval: &Interval) {
        let old_delta = &self.deltas[delta_index];
        let delete = OpBuilder::delete(interval.size() as u64).build();
        let new_delta = new_delta_with_op(old_delta, delete, *interval);
        self.deltas[delta_index] = new_delta;
    }
}

fn new_delta_with_op(delta: &Delta, op: Operation, interval: Interval) -> Delta {
    let mut new_delta = Delta::default();
    let (prefix, interval, suffix) = target_length_split_with_interval(delta.target_len, interval);

    // prefix
    if prefix.is_empty() == false && prefix != interval {
        let intervals = split_interval_with_delta(delta, &prefix);
        intervals.into_iter().for_each(|p_interval| {
            let attributes = delta.attributes_in_interval(p_interval);
            log::debug!(
                "prefix attribute: {:?}, interval: {:?}",
                attributes,
                p_interval
            );
            new_delta.retain(p_interval.size() as u64, attributes);
        });
    }

    new_delta.add(op);

    // suffix
    if suffix.is_empty() == false {
        let intervals = split_interval_with_delta(delta, &suffix);
        intervals.into_iter().for_each(|s_interval| {
            let attributes = delta.attributes_in_interval(s_interval);
            log::debug!(
                "suffix attribute: {:?}, interval: {:?}",
                attributes,
                s_interval
            );
            new_delta.retain(s_interval.size() as u64, attributes);
        });
    }

    delta.compose(&new_delta).unwrap()
}

fn split_interval_with_delta(delta: &Delta, interval: &Interval) -> Vec<Interval> {
    let mut start = 0;
    let mut new_intervals = vec![];
    delta.ops.iter().for_each(|op| match op {
        Operation::Delete(_) => {},
        Operation::Retain(_) => {},
        Operation::Insert(insert) => {
            let len = insert.num_chars() as usize;
            let end = start + len;
            let insert_interval = Interval::new(start, end);
            let new_interval = interval.intersect(insert_interval);

            if !new_interval.is_empty() {
                new_intervals.push(new_interval)
            }
            start += len;
        },
    });
    new_intervals
}

pub fn target_length_split_with_interval(
    length: usize,
    interval: Interval,
) -> (Interval, Interval, Interval) {
    let original_interval = Interval::new(0, length);
    let prefix = original_interval.prefix(interval);
    let suffix = original_interval.suffix(interval);
    (prefix, interval, suffix)
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
