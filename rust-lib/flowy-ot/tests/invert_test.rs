pub mod helper;
use crate::helper::{TestOp::*, *};
use flowy_ot::core::{Delta, Interval, OpBuilder};

#[test]
fn delta_invert_delta_test() {
    let mut delta = Delta::default();
    delta.add(OpBuilder::insert("123").build());

    let mut change = Delta::default();
    change.add(OpBuilder::retain(3).build());
    change.add(OpBuilder::insert("456").build());
    let undo = change.invert_delta(&delta);

    let new_delta = delta.compose(&change).unwrap();
    let delta_after_undo = new_delta.compose(&undo).unwrap();

    assert_eq!(delta_after_undo, delta);
}

#[test]
fn delta_get_ops_in_interval_1() {
    let mut delta = Delta::default();
    let insert_a = OpBuilder::insert("123").build();
    let insert_b = OpBuilder::insert("4").build();

    delta.add(insert_a.clone());
    delta.add(insert_b.clone());

    assert_eq!(
        delta.ops_in_interval(Interval::new(0, 3)),
        vec![delta.ops.last().unwrap().clone()]
    );
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
        delta.ops_in_interval(Interval::new(0, 3)),
        vec![insert_a.clone()]
    );

    assert_eq!(
        delta.ops_in_interval(Interval::new(0, 4)),
        vec![insert_a.clone(), retain_a.clone()]
    );

    assert_eq!(
        delta.ops_in_interval(Interval::new(0, 7)),
        vec![
            insert_a.clone(),
            retain_a.clone(),
            // insert_b and insert_c will be merged into one. insert: "45"
            delta.ops.last().unwrap().clone()
        ]
    );
}
