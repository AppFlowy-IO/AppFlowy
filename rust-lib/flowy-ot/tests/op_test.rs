pub mod helper;

use crate::helper::TestOp::*;
use bytecount::num_chars;
use flowy_ot::core::*;
use helper::*;

#[test]
fn lengths() {
    let mut delta = Delta::default();
    assert_eq!(delta.base_len, 0);
    assert_eq!(delta.target_len, 0);
    delta.retain(5, Attributes::Empty);
    assert_eq!(delta.base_len, 5);
    assert_eq!(delta.target_len, 5);
    delta.insert("abc", Attributes::Empty);
    assert_eq!(delta.base_len, 5);
    assert_eq!(delta.target_len, 8);
    delta.retain(2, Attributes::Empty);
    assert_eq!(delta.base_len, 7);
    assert_eq!(delta.target_len, 10);
    delta.delete(2);
    assert_eq!(delta.base_len, 9);
    assert_eq!(delta.target_len, 10);
}
#[test]
fn sequence() {
    let mut delta = Delta::default();
    delta.retain(5, Attributes::Empty);
    delta.retain(0, Attributes::Empty);
    delta.insert("appflowy", Attributes::Empty);
    delta.insert("", Attributes::Empty);
    delta.delete(3);
    delta.delete(0);
    assert_eq!(delta.ops.len(), 3);
}

#[test]
fn apply_1000() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(50);
        let delta = rng.gen_delta(&s);
        assert_eq!(num_chars(s.as_bytes()), delta.base_len);
        assert_eq!(delta.apply(&s).unwrap().chars().count(), delta.target_len);
    }
}

#[test]
fn apply() {
    let s = "hello world,".to_owned();
    let mut delta_a = Delta::default();
    delta_a.insert(&s, Attributes::Empty);

    let mut delta_b = Delta::default();
    delta_b.retain(s.len(), Attributes::Empty);
    delta_b.insert("appflowy", Attributes::Empty);

    let after_a = delta_a.apply("").unwrap();
    let after_b = delta_b.apply(&after_a).unwrap();
    assert_eq!("hello world,appflowy", &after_b);
}

#[test]
fn base_len_test() {
    let mut delta_a = Delta::default();
    delta_a.insert("a", Attributes::Empty);
    delta_a.insert("b", Attributes::Empty);
    delta_a.insert("c", Attributes::Empty);

    let s = "hello world,".to_owned();
    delta_a.delete(s.len());
    let after_a = delta_a.apply(&s).unwrap();

    delta_a.insert("d", Attributes::Empty);
    assert_eq!("abc", &after_a);
}

#[test]
fn invert() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(50);
        let delta_a = rng.gen_delta(&s);
        let delta_b = delta_a.invert_str(&s);
        assert_eq!(delta_a.base_len, delta_b.target_len);
        assert_eq!(delta_a.target_len, delta_b.base_len);
        assert_eq!(delta_b.apply(&delta_a.apply(&s).unwrap()).unwrap(), s);
    }
}

#[test]
fn empty_ops() {
    let mut delta = Delta::default();
    delta.retain(0, Attributes::Empty);
    delta.insert("", Attributes::Empty);
    delta.delete(0);
    assert_eq!(delta.ops.len(), 0);
}
#[test]
fn eq() {
    let mut delta_a = Delta::default();
    delta_a.delete(1);
    delta_a.insert("lo", Attributes::Empty);
    delta_a.retain(2, Attributes::Empty);
    delta_a.retain(3, Attributes::Empty);
    let mut delta_b = Delta::default();
    delta_b.delete(1);
    delta_b.insert("l", Attributes::Empty);
    delta_b.insert("o", Attributes::Empty);
    delta_b.retain(5, Attributes::Empty);
    assert_eq!(delta_a, delta_b);
    delta_a.delete(1);
    delta_b.retain(1, Attributes::Empty);
    assert_ne!(delta_a, delta_b);
}
#[test]
fn ops_merging() {
    let mut delta = Delta::default();
    assert_eq!(delta.ops.len(), 0);
    delta.retain(2, Attributes::Empty);
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::retain(2).build()));
    delta.retain(3, Attributes::Empty);
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::retain(5).build()));
    delta.insert("abc", Attributes::Empty);
    assert_eq!(delta.ops.len(), 2);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::insert("abc").build()));
    delta.insert("xyz", Attributes::Empty);
    assert_eq!(delta.ops.len(), 2);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::insert("abcxyz").build()));
    delta.delete(1);
    assert_eq!(delta.ops.len(), 3);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::delete(1).build()));
    delta.delete(1);
    assert_eq!(delta.ops.len(), 3);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::delete(2).build()));
}
#[test]
fn is_noop() {
    let mut delta = Delta::default();
    assert!(delta.is_noop());
    delta.retain(5, Attributes::Empty);
    assert!(delta.is_noop());
    delta.retain(3, Attributes::Empty);
    assert!(delta.is_noop());
    delta.insert("lorem", Attributes::Empty);
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
        assert_eq!(ab_prime, ba_prime);

        let after_ab_prime = ab_prime.apply(&s).unwrap();
        let after_ba_prime = ba_prime.apply(&s).unwrap();
        assert_eq!(after_ab_prime, after_ba_prime);
    }
}

#[test]
fn transform2() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "456", 0),
        Transform(0, 1),
        AssertOpsJson(0, r#"[{"insert":"123456"}]"#),
        AssertOpsJson(1, r#"[{"insert":"123456"}]"#),
    ];
    OpTester::new().run_script(ops);
}

#[test]
fn delta_transform_test() {
    let mut a = Delta::default();
    let mut a_s = String::new();
    a.insert("123", AttrsBuilder::new().bold(true).build());
    a_s = a.apply(&a_s).unwrap();
    assert_eq!(&a_s, "123");

    let mut b = Delta::default();
    let mut b_s = String::new();
    b.insert("456", Attributes::Empty);
    b_s = b.apply(&b_s).unwrap();
    assert_eq!(&b_s, "456");

    let (a_prime, b_prime) = a.transform(&b).unwrap();
    assert_eq!(
        r#"[{"insert":"123","attributes":{"bold":"true"}},{"retain":3}]"#,
        serde_json::to_string(&a_prime).unwrap()
    );
    assert_eq!(
        r#"[{"retain":3,"attributes":{"bold":"true"}},{"insert":"456"}]"#,
        serde_json::to_string(&b_prime).unwrap()
    );
}
