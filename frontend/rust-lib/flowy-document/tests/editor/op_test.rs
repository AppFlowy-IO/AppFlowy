#![allow(clippy::all)]
use crate::editor::{Rng, TestBuilder, TestOp::*};
use flowy_document_infra::core::{FlowyDoc, PlainDoc};
use lib_ot::core::*;

#[test]
fn attributes_insert_text() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 3),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn attributes_insert_text_at_head() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 0),
        AssertDocJson(0, r#"[{"insert":"456123"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn attributes_insert_text_at_middle() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 1),
        AssertDocJson(0, r#"[{"insert":"145623"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn delta_get_ops_in_interval_1() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("123").build();
    let insert_b = OpBuilder::insert("4").build();

    delta.add(insert_a.clone());
    delta.add(insert_b.clone());

    let mut iterator = DeltaIter::from_interval(&delta, Interval::new(0, 4));
    assert_eq!(iterator.ops(), delta.ops);
}

#[test]
fn delta_get_ops_in_interval_2() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("123").build();
    let insert_b = OpBuilder::insert("4").build();
    let insert_c = OpBuilder::insert("5").build();
    let retain_a = OpBuilder::retain(3).build();

    delta.add(insert_a.clone());
    delta.add(retain_a.clone());
    delta.add(insert_b.clone());
    delta.add(insert_c.clone());

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(0, 2)).ops(),
        vec![OpBuilder::insert("12").build()]
    );

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(1, 3)).ops(),
        vec![OpBuilder::insert("23").build()]
    );

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(0, 3)).ops(),
        vec![insert_a.clone()]
    );

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(0, 4)).ops(),
        vec![insert_a.clone(), OpBuilder::retain(1).build()]
    );

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(0, 6)).ops(),
        vec![insert_a.clone(), retain_a.clone()]
    );

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(0, 7)).ops(),
        vec![insert_a.clone(), retain_a.clone(), insert_b.clone()]
    );
}

#[test]
fn delta_get_ops_in_interval_3() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("123456").build();
    delta.add(insert_a.clone());
    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(3, 5)).ops(),
        vec![OpBuilder::insert("45").build()]
    );
}

#[test]
fn delta_get_ops_in_interval_4() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("12").build();
    let insert_b = OpBuilder::insert("34").build();
    let insert_c = OpBuilder::insert("56").build();

    delta.ops.push(insert_a.clone());
    delta.ops.push(insert_b.clone());
    delta.ops.push(insert_c.clone());

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(0, 2)).ops(),
        vec![insert_a]
    );
    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(2, 4)).ops(),
        vec![insert_b]
    );
    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(4, 6)).ops(),
        vec![insert_c]
    );

    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(2, 5)).ops(),
        vec![OpBuilder::insert("34").build(), OpBuilder::insert("5").build()]
    );
}

#[test]
fn delta_get_ops_in_interval_5() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("123456").build();
    let insert_b = OpBuilder::insert("789").build();
    delta.ops.push(insert_a.clone());
    delta.ops.push(insert_b.clone());
    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(4, 8)).ops(),
        vec![OpBuilder::insert("56").build(), OpBuilder::insert("78").build()]
    );

    // assert_eq!(
    //     DeltaIter::from_interval(&delta, Interval::new(8, 9)).ops(),
    //     vec![Builder::insert("9").build()]
    // );
}

#[test]
fn delta_get_ops_in_interval_6() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("12345678").build();
    delta.add(insert_a.clone());
    assert_eq!(
        DeltaIter::from_interval(&delta, Interval::new(4, 6)).ops(),
        vec![OpBuilder::insert("56").build()]
    );
}

#[test]
fn delta_get_ops_in_interval_7() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("12345").build();
    let retain_a = OpBuilder::retain(3).build();

    delta.add(insert_a.clone());
    delta.add(retain_a.clone());

    let mut iter_1 = DeltaIter::from_offset(&delta, 2);
    assert_eq!(iter_1.next_op().unwrap(), OpBuilder::insert("345").build());
    assert_eq!(iter_1.next_op().unwrap(), OpBuilder::retain(3).build());

    let mut iter_2 = DeltaIter::new(&delta);
    assert_eq!(iter_2.next_op_with_len(2).unwrap(), OpBuilder::insert("12").build());
    assert_eq!(iter_2.next_op().unwrap(), OpBuilder::insert("345").build());

    assert_eq!(iter_2.next_op().unwrap(), OpBuilder::retain(3).build());
}

#[test]
fn delta_seek_1() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("12345").build();
    let retain_a = OpBuilder::retain(3).build();
    delta.add(insert_a.clone());
    delta.add(retain_a.clone());
    let mut iter = DeltaIter::new(&delta);
    iter.seek::<OpMetric>(1);
    assert_eq!(iter.next_op().unwrap(), OpBuilder::retain(3).build());
}

#[test]
fn delta_seek_2() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("12345").build());

    let mut iter = DeltaIter::new(&delta);
    assert_eq!(iter.next_op_with_len(1).unwrap(), OpBuilder::insert("1").build());
}

#[test]
fn delta_seek_3() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("12345").build());

    let mut iter = DeltaIter::new(&delta);
    assert_eq!(iter.next_op_with_len(2).unwrap(), OpBuilder::insert("12").build());

    assert_eq!(iter.next_op_with_len(2).unwrap(), OpBuilder::insert("34").build());

    assert_eq!(iter.next_op_with_len(2).unwrap(), OpBuilder::insert("5").build());

    assert_eq!(iter.next_op_with_len(1), None);
}

#[test]
fn delta_seek_4() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("12345").build());

    let mut iter = DeltaIter::new(&delta);
    iter.seek::<CharMetric>(3);
    assert_eq!(iter.next_op_with_len(2).unwrap(), OpBuilder::insert("45").build());
}

#[test]
fn delta_seek_5() {
    let mut delta = Delta::default();
    let attributes = AttributeBuilder::new()
        .add_attr(Attribute::Bold(true))
        .add_attr(Attribute::Italic(true))
        .build();

    delta.add(OpBuilder::insert("1234").attributes(attributes.clone()).build());
    delta.add(OpBuilder::insert("\n").build());

    let mut iter = DeltaIter::new(&delta);
    iter.seek::<CharMetric>(0);

    assert_eq!(
        iter.next_op_with_len(4).unwrap(),
        OpBuilder::insert("1234").attributes(attributes).build(),
    );
}

#[test]
fn delta_next_op_len_test() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("12345").build());

    let mut iter = DeltaIter::new(&delta);
    iter.seek::<CharMetric>(3);
    assert_eq!(iter.next_op_len().unwrap(), 2);
    assert_eq!(iter.next_op_with_len(1).unwrap(), OpBuilder::insert("4").build());
    assert_eq!(iter.next_op_len().unwrap(), 1);
    assert_eq!(iter.next_op().unwrap(), OpBuilder::insert("5").build());
}

#[test]
fn delta_next_op_len_test2() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("12345").build());
    let mut iter = DeltaIter::new(&delta);

    assert_eq!(iter.next_op_len().unwrap(), 5);
    assert_eq!(iter.next_op_with_len(5).unwrap(), OpBuilder::insert("12345").build());
    assert_eq!(iter.next_op_len(), None);
}

#[test]
fn delta_next_op_with_len_zero() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("12345").build());
    let mut iter = DeltaIter::new(&delta);
    assert_eq!(iter.next_op_with_len(0), None,);
    assert_eq!(iter.next_op_len().unwrap(), 5);
}

#[test]
fn delta_next_op_with_len_cross_op_return_last() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("12345").build());
    delta.add(OpBuilder::retain(1).build());
    delta.add(OpBuilder::insert("678").build());

    let mut iter = DeltaIter::new(&delta);
    iter.seek::<CharMetric>(4);
    assert_eq!(iter.next_op_len().unwrap(), 1);
    assert_eq!(iter.next_op_with_len(2).unwrap(), OpBuilder::retain(1).build());
}

#[test]
fn lengths() {
    let mut delta = Delta::default();
    assert_eq!(delta.base_len, 0);
    assert_eq!(delta.target_len, 0);
    delta.retain(5, Attributes::default());
    assert_eq!(delta.base_len, 5);
    assert_eq!(delta.target_len, 5);
    delta.insert("abc", Attributes::default());
    assert_eq!(delta.base_len, 5);
    assert_eq!(delta.target_len, 8);
    delta.retain(2, Attributes::default());
    assert_eq!(delta.base_len, 7);
    assert_eq!(delta.target_len, 10);
    delta.delete(2);
    assert_eq!(delta.base_len, 9);
    assert_eq!(delta.target_len, 10);
}
#[test]
fn sequence() {
    let mut delta = Delta::default();
    delta.retain(5, Attributes::default());
    delta.retain(0, Attributes::default());
    delta.insert("appflowy", Attributes::default());
    delta.insert("", Attributes::default());
    delta.delete(3);
    delta.delete(0);
    assert_eq!(delta.ops.len(), 3);
}

#[test]
fn apply_1000() {
    for _ in 0..1 {
        let mut rng = Rng::default();
        let s: FlowyStr = rng.gen_string(50).into();
        let delta = rng.gen_delta(&s);
        assert_eq!(s.count_utf16_code_units(), delta.base_len);
    }
}

#[test]
fn apply() {
    let s = "hello world,".to_owned();
    let mut delta_a = Delta::default();
    delta_a.insert(&s, Attributes::default());

    let mut delta_b = Delta::default();
    delta_b.retain(s.len(), Attributes::default());
    delta_b.insert("appflowy", Attributes::default());

    let after_a = delta_a.apply("").unwrap();
    let after_b = delta_b.apply(&after_a).unwrap();
    assert_eq!("hello world,appflowy", &after_b);
}

#[test]
fn base_len_test() {
    let mut delta_a = Delta::default();
    delta_a.insert("a", Attributes::default());
    delta_a.insert("b", Attributes::default());
    delta_a.insert("c", Attributes::default());

    let s = "hello world,".to_owned();
    delta_a.delete(s.len());
    let after_a = delta_a.apply(&s).unwrap();

    delta_a.insert("d", Attributes::default());
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
    delta.retain(0, Attributes::default());
    delta.insert("", Attributes::default());
    delta.delete(0);
    assert_eq!(delta.ops.len(), 0);
}
#[test]
fn eq() {
    let mut delta_a = Delta::default();
    delta_a.delete(1);
    delta_a.insert("lo", Attributes::default());
    delta_a.retain(2, Attributes::default());
    delta_a.retain(3, Attributes::default());
    let mut delta_b = Delta::default();
    delta_b.delete(1);
    delta_b.insert("l", Attributes::default());
    delta_b.insert("o", Attributes::default());
    delta_b.retain(5, Attributes::default());
    assert_eq!(delta_a, delta_b);
    delta_a.delete(1);
    delta_b.retain(1, Attributes::default());
    assert_ne!(delta_a, delta_b);
}
#[test]
fn ops_merging() {
    let mut delta = Delta::default();
    assert_eq!(delta.ops.len(), 0);
    delta.retain(2, Attributes::default());
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::retain(2).build()));
    delta.retain(3, Attributes::default());
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::retain(5).build()));
    delta.insert("abc", Attributes::default());
    assert_eq!(delta.ops.len(), 2);
    assert_eq!(delta.ops.last(), Some(&OpBuilder::insert("abc").build()));
    delta.insert("xyz", Attributes::default());
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
    delta.retain(5, Attributes::default());
    assert!(delta.is_noop());
    delta.retain(3, Attributes::default());
    assert!(delta.is_noop());
    delta.insert("lorem", Attributes::default());
    assert!(!delta.is_noop());
}
#[test]
fn compose() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(20);
        let a = rng.gen_delta(&s);
        let after_a: FlowyStr = a.apply(&s).unwrap().into();
        assert_eq!(a.target_len, after_a.count_utf16_code_units());

        let b = rng.gen_delta(&after_a);
        let after_b: FlowyStr = b.apply(&after_a).unwrap().into();
        assert_eq!(b.target_len, after_b.count_utf16_code_units());

        let ab = a.compose(&b).unwrap();
        assert_eq!(ab.target_len, b.target_len);
        let after_ab: FlowyStr = ab.apply(&s).unwrap().into();
        assert_eq!(after_b, after_ab);
    }
}
#[test]
fn transform_random_delta() {
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
fn transform_with_two_delta_test() {
    let mut a = Delta::default();
    let mut a_s = String::new();
    a.insert("123", AttributeBuilder::new().add_attr(Attribute::Bold(true)).build());
    a_s = a.apply(&a_s).unwrap();
    assert_eq!(&a_s, "123");

    let mut b = Delta::default();
    let mut b_s = String::new();
    b.insert("456", Attributes::default());
    b_s = b.apply(&b_s).unwrap();
    assert_eq!(&b_s, "456");

    let (a_prime, b_prime) = a.transform(&b).unwrap();
    assert_eq!(
        r#"[{"insert":"123","attributes":{"bold":true}},{"retain":3}]"#,
        serde_json::to_string(&a_prime).unwrap()
    );
    assert_eq!(
        r#"[{"retain":3,"attributes":{"bold":true}},{"insert":"456"}]"#,
        serde_json::to_string(&b_prime).unwrap()
    );

    let new_a = a.compose(&b_prime).unwrap();
    let new_b = b.compose(&a_prime).unwrap();
    assert_eq!(
        r#"[{"insert":"123","attributes":{"bold":true}},{"insert":"456"}]"#,
        serde_json::to_string(&new_a).unwrap()
    );

    assert_eq!(
        r#"[{"insert":"123","attributes":{"bold":true}},{"insert":"456"}]"#,
        serde_json::to_string(&new_b).unwrap()
    );
}

#[test]
fn transform_two_plain_delta_test() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "456", 0),
        Transform(0, 1),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
        AssertDocJson(1, r#"[{"insert":"123456"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn transform_two_plain_delta_test2() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "456", 0),
        TransformPrime(0, 1),
        DocComposePrime(0, 1),
        DocComposePrime(1, 0),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
        AssertDocJson(1, r#"[{"insert":"123456"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn transform_two_non_seq_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "456", 0),
        TransformPrime(0, 1),
        AssertPrimeJson(0, r#"[{"insert":"123"},{"retain":3}]"#),
        AssertPrimeJson(1, r#"[{"retain":3},{"insert":"456"}]"#),
        DocComposePrime(0, 1),
        Insert(1, "78", 3),
        Insert(1, "9", 5),
        DocComposePrime(1, 0),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
        AssertDocJson(1, r#"[{"insert":"123456789"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn transform_two_conflict_non_seq_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "456", 0),
        TransformPrime(0, 1),
        DocComposePrime(0, 1),
        Insert(1, "78", 0),
        DocComposePrime(1, 0),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
        AssertDocJson(1, r#"[{"insert":"12378456"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn delta_invert_no_attribute_delta() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("123").build());

    let mut change = Delta::default();
    change.add(OpBuilder::retain(3).build());
    change.add(OpBuilder::insert("456").build());
    let undo = change.invert(&delta);

    let new_delta = delta.compose(&change).unwrap();
    let delta_after_undo = new_delta.compose(&undo).unwrap();

    assert_eq!(delta_after_undo, delta);
}

#[test]
fn delta_invert_no_attribute_delta2() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "4567", 0),
        Invert(0, 1),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn delta_invert_attribute_delta_with_no_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
        Insert(1, "4567", 0),
        Invert(0, 1),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":"true"}}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn delta_invert_attribute_delta_with_no_attribute_delta2() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Insert(0, "456", 3),
        AssertDocJson(
            0,
            r#"[
            {"insert":"123456","attributes":{"bold":"true"}}]
            "#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true"}}, 
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
        ),
        Insert(1, "abc", 0),
        Invert(0, 1),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true"}},
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
        ),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn delta_invert_no_attribute_delta_with_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "4567", 0),
        Bold(1, Interval::new(0, 3), true),
        AssertDocJson(1, r#"[{"insert":"456","attributes":{"bold":"true"}},{"insert":"7"}]"#),
        Invert(0, 1),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn delta_invert_no_attribute_delta_with_attribute_delta2() {
    let ops = vec![
        Insert(0, "123", 0),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
        Insert(1, "abc", 0),
        Bold(1, Interval::new(0, 3), true),
        Insert(1, "d", 3),
        Italic(1, Interval::new(1, 3), true),
        AssertDocJson(
            1,
            r#"[{"insert":"a","attributes":{"bold":"true"}},{"insert":"bc","attributes":{"bold":"true","italic":"true"}},{"insert":"d","attributes":{"bold":"true"}}]"#,
        ),
        Invert(0, 1),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
fn delta_invert_attribute_delta_with_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Insert(0, "456", 3),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":"true"}}]"#),
        Italic(0, Interval::new(2, 4), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true"}},
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
        ),
        Insert(1, "abc", 0),
        Bold(1, Interval::new(0, 3), true),
        Insert(1, "d", 3),
        Italic(1, Interval::new(1, 3), true),
        AssertDocJson(
            1,
            r#"[
            {"insert":"a","attributes":{"bold":"true"}},
            {"insert":"bc","attributes":{"bold":"true","italic":"true"}},
            {"insert":"d","attributes":{"bold":"true"}}
            ]"#,
        ),
        Invert(0, 1),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":"true"}},
            {"insert":"34","attributes":{"bold":"true","italic":"true"}},
            {"insert":"56","attributes":{"bold":"true"}}
            ]"#,
        ),
    ];
    TestBuilder::new().run_script::<PlainDoc>(ops);
}

#[test]
#[should_panic]
fn delta_compose_with_missing_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "4", 3),
        DocComposeDelta(1, 0),
        AssertDocJson(0, r#"[{"insert":"1234\n"}]"#),
        AssertStr(1, r#"4\n"#),
    ];
    TestBuilder::new().run_script::<FlowyDoc>(ops);
}
