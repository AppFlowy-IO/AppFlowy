mod helper;

use crate::helper::Rng;
use bytecount::num_chars;
use flowy_ot::{
    delta::Delta,
    operation::{OpType, OperationBuilder},
};

#[test]
fn lengths() {
    let mut delta = Delta::default();
    assert_eq!(delta.base_len, 0);
    assert_eq!(delta.target_len, 0);
    delta.retain(5);
    assert_eq!(delta.base_len, 5);
    assert_eq!(delta.target_len, 5);
    delta.insert("abc");
    assert_eq!(delta.base_len, 5);
    assert_eq!(delta.target_len, 8);
    delta.retain(2);
    assert_eq!(delta.base_len, 7);
    assert_eq!(delta.target_len, 10);
    delta.delete(2);
    assert_eq!(delta.base_len, 9);
    assert_eq!(delta.target_len, 10);
}
#[test]
fn sequence() {
    let mut delta = Delta::default();
    delta.retain(5);
    delta.retain(0);
    delta.insert("lorem");
    delta.insert("");
    delta.delete(3);
    delta.delete(0);
    assert_eq!(delta.ops.len(), 3);
}

#[test]
fn apply() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(50);
        let delta = rng.gen_delta(&s);
        assert_eq!(num_chars(s.as_bytes()), delta.base_len);
        assert_eq!(delta.apply(&s).unwrap().chars().count(), delta.target_len);
    }
}
#[test]
fn invert() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(50);
        let delta_a = rng.gen_delta(&s);
        let delta_b = delta_a.invert(&s);
        assert_eq!(delta_a.base_len, delta_b.target_len);
        assert_eq!(delta_a.target_len, delta_b.base_len);
        assert_eq!(delta_b.apply(&delta_a.apply(&s).unwrap()).unwrap(), s);
    }
}
#[test]
fn empty_ops() {
    let mut delta = Delta::default();
    delta.retain(0);
    delta.insert("");
    delta.delete(0);
    assert_eq!(delta.ops.len(), 0);
}
#[test]
fn eq() {
    let mut delta_a = Delta::default();
    delta_a.delete(1);
    delta_a.insert("lo");
    delta_a.retain(2);
    delta_a.retain(3);
    let mut delta_b = Delta::default();
    delta_b.delete(1);
    delta_b.insert("l");
    delta_b.insert("o");
    delta_b.retain(5);
    assert_eq!(delta_a, delta_b);
    delta_a.delete(1);
    delta_b.retain(1);
    assert_ne!(delta_a, delta_b);
}
#[test]
fn ops_merging() {
    let mut delta = Delta::default();
    assert_eq!(delta.ops.len(), 0);
    delta.retain(2);
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&OperationBuilder::retain(2).build()));
    delta.retain(3);
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&OperationBuilder::retain(5).build()));
    delta.insert("abc");
    assert_eq!(delta.ops.len(), 2);
    assert_eq!(
        delta.ops.last(),
        Some(&OperationBuilder::insert("abc".to_owned()).build())
    );
    delta.insert("xyz");
    assert_eq!(delta.ops.len(), 2);
    assert_eq!(
        delta.ops.last(),
        Some(&OperationBuilder::insert("abcxyz".to_owned()).build())
    );
    delta.delete(1);
    assert_eq!(delta.ops.len(), 3);
    assert_eq!(delta.ops.last(), Some(&OperationBuilder::delete(1).build()));
    delta.delete(1);
    assert_eq!(delta.ops.len(), 3);
    assert_eq!(delta.ops.last(), Some(&OperationBuilder::delete(2).build()));
}
#[test]
fn is_noop() {
    let mut delta = Delta::default();
    assert!(delta.is_noop());
    delta.retain(5);
    assert!(delta.is_noop());
    delta.retain(3);
    assert!(delta.is_noop());
    delta.insert("lorem");
    assert!(!delta.is_noop());
}
#[test]
fn compose() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(20);
        let a = rng.gen_delta(&s);
        let after_a = a.apply(&s).unwrap();
        assert_eq!(a.target_len, num_chars(after_a.as_bytes()));

        let b = rng.gen_delta(&after_a);
        let after_b = b.apply(&after_a).unwrap();
        assert_eq!(b.target_len, num_chars(after_b.as_bytes()));

        let ab = a.compose(&b).unwrap();
        assert_eq!(ab.target_len, b.target_len);
        let after_ab = ab.apply(&s).unwrap();
        assert_eq!(after_b, after_ab);
    }
}
#[test]
fn transform() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(20);
        let a = rng.gen_delta(&s);
        let b = rng.gen_delta(&s);
        let (a_prime, b_prime) = a.transform(&b).unwrap();
        let ab_prime = a.compose(&b_prime).unwrap();
        let ba_prime = b.compose(&a_prime).unwrap();
        let after_ab_prime = ab_prime.apply(&s).unwrap();
        let after_ba_prime = ba_prime.apply(&s).unwrap();
        assert_eq!(ab_prime, ba_prime);
        assert_eq!(after_ab_prime, after_ba_prime);
    }
}
