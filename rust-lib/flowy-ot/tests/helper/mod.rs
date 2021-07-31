use flowy_ot::delta::Delta;
use rand::{prelude::*, Rng as WrappedRng};

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
        let mut op = Delta::default();
        loop {
            let left = s.chars().count() - op.base_len();
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
                    op.insert(&self.gen_string(i));
                },
                f if f < 0.4 => {
                    op.delete(i as u64);
                },
                _ => {
                    op.retain(i as u64);
                },
            }
        }
        if self.0.gen_range(0.0, 1.0) < 0.3 {
            op.insert(&("1".to_owned() + &self.gen_string(10)));
        }
        op
    }
}
