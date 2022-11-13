#![allow(clippy::all)]
use crate::editor::{Rng, TestBuilder, TestOp::*};
use flowy_sync::client_document::{EmptyDocument, NewlineDocument};
use lib_ot::text_delta::DeltaTextOperationBuilder;
use lib_ot::{core::Interval, core::*, text_delta::DeltaTextOperations};

#[test]
fn attributes_insert_text() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 3),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn attributes_insert_text_at_head() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 0),
        AssertDocJson(0, r#"[{"insert":"456123"}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn attributes_insert_text_at_middle() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(0, "456", 1),
        AssertDocJson(0, r#"[{"insert":"145623"}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn delta_get_ops_in_interval_1() {
    let delta = DeltaTextOperationBuilder::new().insert("123").insert("4").build();

    let mut iterator = OperationIterator::from_interval(&delta, Interval::new(0, 4));
    assert_eq!(iterator.ops(), delta.ops);
}

#[test]
fn delta_get_ops_in_interval_2() {
    let mut delta = DeltaTextOperations::default();
    let insert_a = DeltaOperation::insert("123");
    let insert_b = DeltaOperation::insert("4");
    let insert_c = DeltaOperation::insert("5");
    let retain_a = DeltaOperation::retain(3);

    delta.add(insert_a.clone());
    delta.add(retain_a.clone());
    delta.add(insert_b.clone());
    delta.add(insert_c.clone());

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(0, 2)).ops(),
        vec![DeltaOperation::insert("12")]
    );

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(1, 3)).ops(),
        vec![DeltaOperation::insert("23")]
    );

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(0, 3)).ops(),
        vec![insert_a.clone()]
    );

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(0, 4)).ops(),
        vec![insert_a.clone(), DeltaOperation::retain(1)]
    );

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(0, 6)).ops(),
        vec![insert_a.clone(), retain_a.clone()]
    );

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(0, 7)).ops(),
        vec![insert_a.clone(), retain_a.clone(), insert_b.clone()]
    );
}

#[test]
fn delta_get_ops_in_interval_3() {
    let mut delta = DeltaTextOperations::default();
    let insert_a = DeltaOperation::insert("123456");
    delta.add(insert_a.clone());
    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(3, 5)).ops(),
        vec![DeltaOperation::insert("45")]
    );
}

#[test]
fn delta_get_ops_in_interval_4() {
    let mut delta = DeltaTextOperations::default();
    let insert_a = DeltaOperation::insert("12");
    let insert_b = DeltaOperation::insert("34");
    let insert_c = DeltaOperation::insert("56");

    delta.ops.push(insert_a.clone());
    delta.ops.push(insert_b.clone());
    delta.ops.push(insert_c.clone());

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(0, 2)).ops(),
        vec![insert_a]
    );
    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(2, 4)).ops(),
        vec![insert_b]
    );
    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(4, 6)).ops(),
        vec![insert_c]
    );

    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(2, 5)).ops(),
        vec![DeltaOperation::insert("34"), DeltaOperation::insert("5")]
    );
}

#[test]
fn delta_get_ops_in_interval_5() {
    let mut delta = DeltaTextOperations::default();
    let insert_a = DeltaOperation::insert("123456");
    let insert_b = DeltaOperation::insert("789");
    delta.ops.push(insert_a.clone());
    delta.ops.push(insert_b.clone());
    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(4, 8)).ops(),
        vec![DeltaOperation::insert("56"), DeltaOperation::insert("78")]
    );

    // assert_eq!(
    //     DeltaIter::from_interval(&delta, Interval::new(8, 9)).ops(),
    //     vec![Builder::insert("9")]
    // );
}

#[test]
fn delta_get_ops_in_interval_6() {
    let mut delta = DeltaTextOperations::default();
    let insert_a = DeltaOperation::insert("12345678");
    delta.add(insert_a.clone());
    assert_eq!(
        OperationIterator::from_interval(&delta, Interval::new(4, 6)).ops(),
        vec![DeltaOperation::insert("56")]
    );
}

#[test]
fn delta_get_ops_in_interval_7() {
    let mut delta = DeltaTextOperations::default();
    let insert_a = DeltaOperation::insert("12345");
    let retain_a = DeltaOperation::retain(3);

    delta.add(insert_a.clone());
    delta.add(retain_a.clone());

    let mut iter_1 = OperationIterator::from_offset(&delta, 2);
    assert_eq!(iter_1.next_op().unwrap(), DeltaOperation::insert("345"));
    assert_eq!(iter_1.next_op().unwrap(), DeltaOperation::retain(3));

    let mut iter_2 = OperationIterator::new(&delta);
    assert_eq!(iter_2.next_op_with_len(2).unwrap(), DeltaOperation::insert("12"));
    assert_eq!(iter_2.next_op().unwrap(), DeltaOperation::insert("345"));

    assert_eq!(iter_2.next_op().unwrap(), DeltaOperation::retain(3));
}

#[test]
fn delta_op_seek() {
    let mut delta = DeltaTextOperations::default();
    let insert_a = DeltaOperation::insert("12345");
    let retain_a = DeltaOperation::retain(3);
    delta.add(insert_a.clone());
    delta.add(retain_a.clone());
    let mut iter = OperationIterator::new(&delta);
    iter.seek::<OpMetric>(1);
    assert_eq!(iter.next_op().unwrap(), retain_a);
}

#[test]
fn delta_utf16_code_unit_seek() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("12345"));

    let mut iter = OperationIterator::new(&delta);
    iter.seek::<Utf16CodeUnitMetric>(3);
    assert_eq!(iter.next_op_with_len(2).unwrap(), DeltaOperation::insert("45"));
}

#[test]
fn delta_utf16_code_unit_seek_with_attributes() {
    let mut delta = DeltaTextOperations::default();
    let attributes = AttributeBuilder::new()
        .insert("bold", true)
        .insert("italic", true)
        .build();

    delta.add(DeltaOperation::insert_with_attributes("1234", attributes.clone()));
    delta.add(DeltaOperation::insert("\n"));

    let mut iter = OperationIterator::new(&delta);
    iter.seek::<Utf16CodeUnitMetric>(0);

    assert_eq!(
        iter.next_op_with_len(4).unwrap(),
        DeltaOperation::insert_with_attributes("1234", attributes),
    );
}

#[test]
fn delta_next_op_len() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("12345"));
    let mut iter = OperationIterator::new(&delta);
    assert_eq!(iter.next_op_with_len(2).unwrap(), DeltaOperation::insert("12"));
    assert_eq!(iter.next_op_with_len(2).unwrap(), DeltaOperation::insert("34"));
    assert_eq!(iter.next_op_with_len(2).unwrap(), DeltaOperation::insert("5"));
    assert_eq!(iter.next_op_with_len(1), None);
}

#[test]
fn delta_next_op_len_with_chinese() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("你好"));

    let mut iter = OperationIterator::new(&delta);
    assert_eq!(iter.next_op_len().unwrap(), 2);
    assert_eq!(iter.next_op_with_len(2).unwrap(), DeltaOperation::insert("你好"));
}

#[test]
fn delta_next_op_len_with_english() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("ab"));
    let mut iter = OperationIterator::new(&delta);
    assert_eq!(iter.next_op_len().unwrap(), 2);
    assert_eq!(iter.next_op_with_len(2).unwrap(), DeltaOperation::insert("ab"));
}

#[test]
fn delta_next_op_len_after_seek() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("12345"));
    let mut iter = OperationIterator::new(&delta);
    assert_eq!(iter.next_op_len().unwrap(), 5);
    iter.seek::<Utf16CodeUnitMetric>(3);
    assert_eq!(iter.next_op_len().unwrap(), 2);
    assert_eq!(iter.next_op_with_len(1).unwrap(), DeltaOperation::insert("4"));
    assert_eq!(iter.next_op_len().unwrap(), 1);
    assert_eq!(iter.next_op().unwrap(), DeltaOperation::insert("5"));
}

#[test]
fn delta_next_op_len_none() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("12345"));
    let mut iter = OperationIterator::new(&delta);

    assert_eq!(iter.next_op_len().unwrap(), 5);
    assert_eq!(iter.next_op_with_len(5).unwrap(), DeltaOperation::insert("12345"));
    assert_eq!(iter.next_op_len(), None);
}

#[test]
fn delta_next_op_with_len_zero() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("12345"));
    let mut iter = OperationIterator::new(&delta);
    assert_eq!(iter.next_op_with_len(0), None,);
    assert_eq!(iter.next_op_len().unwrap(), 5);
}

#[test]
fn delta_next_op_with_len_cross_op_return_last() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("12345"));
    delta.add(DeltaOperation::retain(1));
    delta.add(DeltaOperation::insert("678"));

    let mut iter = OperationIterator::new(&delta);
    iter.seek::<Utf16CodeUnitMetric>(4);
    assert_eq!(iter.next_op_len().unwrap(), 1);
    assert_eq!(iter.next_op_with_len(2).unwrap(), DeltaOperation::retain(1));
}

#[test]
fn lengths() {
    let mut delta = DeltaTextOperations::default();
    assert_eq!(delta.utf16_base_len, 0);
    assert_eq!(delta.utf16_target_len, 0);
    delta.retain(5, AttributeHashMap::default());
    assert_eq!(delta.utf16_base_len, 5);
    assert_eq!(delta.utf16_target_len, 5);
    delta.insert("abc", AttributeHashMap::default());
    assert_eq!(delta.utf16_base_len, 5);
    assert_eq!(delta.utf16_target_len, 8);
    delta.retain(2, AttributeHashMap::default());
    assert_eq!(delta.utf16_base_len, 7);
    assert_eq!(delta.utf16_target_len, 10);
    delta.delete(2);
    assert_eq!(delta.utf16_base_len, 9);
    assert_eq!(delta.utf16_target_len, 10);
}
#[test]
fn sequence() {
    let mut delta = DeltaTextOperations::default();
    delta.retain(5, AttributeHashMap::default());
    delta.retain(0, AttributeHashMap::default());
    delta.insert("appflowy", AttributeHashMap::default());
    delta.insert("", AttributeHashMap::default());
    delta.delete(3);
    delta.delete(0);
    assert_eq!(delta.ops.len(), 3);
}

#[test]
fn apply_1000() {
    for _ in 0..1 {
        let mut rng = Rng::default();
        let s: OTString = rng.gen_string(50).into();
        let delta = rng.gen_delta(&s);
        assert_eq!(s.utf16_len(), delta.utf16_base_len);
    }
}

#[test]
fn apply_test() {
    let s = "hello";
    let delta_a = DeltaBuilder::new().insert(s).build();
    let delta_b = DeltaBuilder::new().retain(s.len()).insert(", AppFlowy").build();

    let after_a = delta_a.content().unwrap();
    let after_b = delta_b.apply(&after_a).unwrap();
    assert_eq!("hello, AppFlowy", &after_b);
}

#[test]
fn base_len_test() {
    let mut delta_a = DeltaTextOperations::default();
    delta_a.insert("a", AttributeHashMap::default());
    delta_a.insert("b", AttributeHashMap::default());
    delta_a.insert("c", AttributeHashMap::default());

    let s = "hello world,".to_owned();
    delta_a.delete(s.len());
    let after_a = delta_a.apply(&s).unwrap();

    delta_a.insert("d", AttributeHashMap::default());
    assert_eq!("abc", &after_a);
}

#[test]
fn invert() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(50);
        let delta_a = rng.gen_delta(&s);
        let delta_b = delta_a.invert_str(&s);
        assert_eq!(delta_a.utf16_base_len, delta_b.utf16_target_len);
        assert_eq!(delta_a.utf16_target_len, delta_b.utf16_base_len);
        assert_eq!(delta_b.apply(&delta_a.apply(&s).unwrap()).unwrap(), s);
    }
}

#[test]
fn invert_test() {
    let s = "hello world";
    let delta = DeltaBuilder::new().insert(s).build();
    let invert_delta = delta.invert_str("");
    assert_eq!(delta.utf16_base_len, invert_delta.utf16_target_len);
    assert_eq!(delta.utf16_target_len, invert_delta.utf16_base_len);

    assert_eq!(invert_delta.apply(s).unwrap(), "")
}

#[test]
fn empty_ops() {
    let mut delta = DeltaTextOperations::default();
    delta.retain(0, AttributeHashMap::default());
    delta.insert("", AttributeHashMap::default());
    delta.delete(0);
    assert_eq!(delta.ops.len(), 0);
}
#[test]
fn eq() {
    let mut delta_a = DeltaTextOperations::default();
    delta_a.delete(1);
    delta_a.insert("lo", AttributeHashMap::default());
    delta_a.retain(2, AttributeHashMap::default());
    delta_a.retain(3, AttributeHashMap::default());
    let mut delta_b = DeltaTextOperations::default();
    delta_b.delete(1);
    delta_b.insert("l", AttributeHashMap::default());
    delta_b.insert("o", AttributeHashMap::default());
    delta_b.retain(5, AttributeHashMap::default());
    assert_eq!(delta_a, delta_b);
    delta_a.delete(1);
    delta_b.retain(1, AttributeHashMap::default());
    assert_ne!(delta_a, delta_b);
}
#[test]
fn ops_merging() {
    let mut delta = DeltaTextOperations::default();
    assert_eq!(delta.ops.len(), 0);
    delta.retain(2, AttributeHashMap::default());
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&DeltaOperation::retain(2)));
    delta.retain(3, AttributeHashMap::default());
    assert_eq!(delta.ops.len(), 1);
    assert_eq!(delta.ops.last(), Some(&DeltaOperation::retain(5)));
    delta.insert("abc", AttributeHashMap::default());
    assert_eq!(delta.ops.len(), 2);
    assert_eq!(delta.ops.last(), Some(&DeltaOperation::insert("abc")));
    delta.insert("xyz", AttributeHashMap::default());
    assert_eq!(delta.ops.len(), 2);
    assert_eq!(delta.ops.last(), Some(&DeltaOperation::insert("abcxyz")));
    delta.delete(1);
    assert_eq!(delta.ops.len(), 3);
    assert_eq!(delta.ops.last(), Some(&DeltaOperation::delete(1)));
    delta.delete(1);
    assert_eq!(delta.ops.len(), 3);
    assert_eq!(delta.ops.last(), Some(&DeltaOperation::delete(2)));
}

#[test]
fn is_noop() {
    let mut delta = DeltaTextOperations::default();
    assert!(delta.is_noop());
    delta.retain(5, AttributeHashMap::default());
    assert!(delta.is_noop());
    delta.retain(3, AttributeHashMap::default());
    assert!(delta.is_noop());
    delta.insert("lorem", AttributeHashMap::default());
    assert!(!delta.is_noop());
}
#[test]
fn compose() {
    for _ in 0..1000 {
        let mut rng = Rng::default();
        let s = rng.gen_string(20);
        let a = rng.gen_delta(&s);
        let after_a: OTString = a.apply(&s).unwrap().into();
        assert_eq!(a.utf16_target_len, after_a.utf16_len());

        let b = rng.gen_delta(&after_a);
        let after_b: OTString = b.apply(&after_a).unwrap().into();
        assert_eq!(b.utf16_target_len, after_b.utf16_len());

        let ab = a.compose(&b).unwrap();
        assert_eq!(ab.utf16_target_len, b.utf16_target_len);
        let after_ab: OTString = ab.apply(&s).unwrap().into();
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
fn transform_with_two_delta() {
    let mut a = DeltaTextOperations::default();
    let mut a_s = String::new();
    a.insert("123", AttributeBuilder::new().insert("bold", true).build());
    a_s = a.apply(&a_s).unwrap();
    assert_eq!(&a_s, "123");

    let mut b = DeltaTextOperations::default();
    let mut b_s = String::new();
    b.insert("456", AttributeHashMap::default());
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
fn transform_two_plain_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "456", 0),
        Transform(0, 1),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
        AssertDocJson(1, r#"[{"insert":"123456"}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn transform_two_plain_delta2() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "456", 0),
        TransformPrime(0, 1),
        DocComposePrime(0, 1),
        DocComposePrime(1, 0),
        AssertDocJson(0, r#"[{"insert":"123456"}]"#),
        AssertDocJson(1, r#"[{"insert":"123456"}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
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
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
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
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn delta_invert_no_attribute_delta() {
    let mut delta = DeltaTextOperations::default();
    delta.add(DeltaOperation::insert("123"));

    let mut change = DeltaTextOperations::default();
    change.add(DeltaOperation::retain(3));
    change.add(DeltaOperation::insert("456"));
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
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn delta_invert_attribute_delta_with_no_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":true}}]"#),
        Insert(1, "4567", 0),
        Invert(0, 1),
        AssertDocJson(0, r#"[{"insert":"123","attributes":{"bold":true}}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
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
            {"insert":"123456","attributes":{"bold":true}}]
            "#,
        ),
        Italic(0, Interval::new(2, 4), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":true}}, 
            {"insert":"34","attributes":{"bold":true,"italic":true}},
            {"insert":"56","attributes":{"bold":true}}
            ]"#,
        ),
        Insert(1, "abc", 0),
        Invert(0, 1),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":true}},
            {"insert":"34","attributes":{"bold":true,"italic":true}},
            {"insert":"56","attributes":{"bold":true}}
            ]"#,
        ),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn delta_invert_no_attribute_delta_with_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Insert(1, "4567", 0),
        Bold(1, Interval::new(0, 3), true),
        AssertDocJson(1, r#"[{"insert":"456","attributes":{"bold":true}},{"insert":"7"}]"#),
        Invert(0, 1),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
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
            r#"[{"insert":"a","attributes":{"bold":true}},{"insert":"bc","attributes":{"bold":true,"italic":true}},{"insert":"d","attributes":{"bold":true}}]"#,
        ),
        Invert(0, 1),
        AssertDocJson(0, r#"[{"insert":"123"}]"#),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn delta_invert_attribute_delta_with_attribute_delta() {
    let ops = vec![
        Insert(0, "123", 0),
        Bold(0, Interval::new(0, 3), true),
        Insert(0, "456", 3),
        AssertDocJson(0, r#"[{"insert":"123456","attributes":{"bold":true}}]"#),
        Italic(0, Interval::new(2, 4), true),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":true}},
            {"insert":"34","attributes":{"bold":true,"italic":true}},
            {"insert":"56","attributes":{"bold":true}}
            ]"#,
        ),
        Insert(1, "abc", 0),
        Bold(1, Interval::new(0, 3), true),
        Insert(1, "d", 3),
        Italic(1, Interval::new(1, 3), true),
        AssertDocJson(
            1,
            r#"[
            {"insert":"a","attributes":{"bold":true}},
            {"insert":"bc","attributes":{"bold":true,"italic":true}},
            {"insert":"d","attributes":{"bold":true}}
            ]"#,
        ),
        Invert(0, 1),
        AssertDocJson(
            0,
            r#"[
            {"insert":"12","attributes":{"bold":true}},
            {"insert":"34","attributes":{"bold":true,"italic":true}},
            {"insert":"56","attributes":{"bold":true}}
            ]"#,
        ),
    ];
    TestBuilder::new().run_scripts::<EmptyDocument>(ops);
}

#[test]
fn delta_compose_str() {
    let ops = vec![
        Insert(0, "1", 0),
        Insert(0, "2", 1),
        AssertDocJson(0, r#"[{"insert":"12\n"}]"#),
    ];
    TestBuilder::new().run_scripts::<NewlineDocument>(ops);
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
    TestBuilder::new().run_scripts::<NewlineDocument>(ops);
}
