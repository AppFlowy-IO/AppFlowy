use crate::{
    client::{History, UndoResult},
    core::{
        Attribute,
        Attributes,
        AttributesDataRule,
        AttrsBuilder,
        Delta,
        Interval,
        OpBuilder,
        Operation,
    },
};

pub struct Document {
    data: Delta,
    history: History,
}

impl Document {
    pub fn new() -> Self {
        Document {
            data: Delta::new(),
            history: History::new(),
        }
    }

    pub fn edit(&mut self, index: usize, text: &str) {
        if self.data.target_len < index {
            log::error!(
                "{} out of bounds. should 0..{}",
                index,
                self.data.target_len
            );
        }
        let probe = Interval::new(index, index + 1);
        let mut attributes = self.data.get_attributes(probe);
        if attributes == Attributes::Empty {
            attributes = Attributes::Follow;
        }
        let insert = OpBuilder::insert(text).attributes(attributes).build();
        let interval = Interval::new(index, index);

        self.update_with_op(insert, interval);
    }

    pub fn format(&mut self, interval: Interval, attribute: Attribute, enable: bool) {
        let attributes = match enable {
            true => AttrsBuilder::new().add_attribute(attribute).build(),
            false => AttrsBuilder::new().remove_attribute(attribute).build(),
        };

        self.update_with_attribute(attributes, interval);
    }

    pub fn undo(&mut self) -> UndoResult { unimplemented!() }

    pub fn redo(&mut self) -> UndoResult { unimplemented!() }

    pub fn delete(&mut self, interval: Interval) {
        let delete = OpBuilder::delete(interval.size() as u64).build();
        self.update_with_op(delete, interval);
    }

    pub fn to_json(&self) -> String { self.data.to_json() }

    pub fn data(&self) -> &Delta { &self.data }

    pub fn set_data(&mut self, data: Delta) { self.data = data; }

    fn update_with_op(&mut self, op: Operation, interval: Interval) {
        let mut new_delta = Delta::default();
        let (prefix, interval, suffix) = split_length_with_interval(self.data.target_len, interval);

        // prefix
        if prefix.is_empty() == false && prefix != interval {
            let intervals = split_interval_with_delta(&self.data, &prefix);
            intervals.into_iter().for_each(|i| {
                let attributes = self.data.get_attributes(i);
                log::debug!("prefix attribute: {:?}, interval: {:?}", attributes, i);
                new_delta.retain(i.size() as u64, attributes);
            });
        }

        log::debug!("add new op: {:?}", op);
        new_delta.add(op);

        // suffix
        if suffix.is_empty() == false {
            let intervals = split_interval_with_delta(&self.data, &suffix);
            intervals.into_iter().for_each(|i| {
                let attributes = self.data.get_attributes(i);
                log::debug!("suffix attribute: {:?}, interval: {:?}", attributes, i);
                new_delta.retain(i.size() as u64, attributes);
            });
        }

        let new_data = self.data.compose(&new_delta).unwrap();
        self.data = new_data;
    }

    pub fn update_with_attribute(&mut self, mut attributes: Attributes, interval: Interval) {
        let old_attributes = self.data.get_attributes(interval);
        log::debug!(
            "merge attributes: {:?}, with old: {:?}",
            attributes,
            old_attributes
        );
        let new_attributes = match &mut attributes {
            Attributes::Follow => old_attributes,
            Attributes::Custom(attr_data) => {
                attr_data.merge(old_attributes.data());
                attr_data.clone().into_attributes()
            },
            Attributes::Empty => Attributes::Empty,
        };

        log::debug!("new attributes: {:?}", new_attributes);
        let retain = OpBuilder::retain(interval.size() as u64)
            .attributes(new_attributes)
            .build();

        log::debug!(
            "Update delta with new attributes: {:?} at: {:?}",
            retain,
            interval
        );

        self.update_with_op(retain, interval);
    }
}

pub fn transform(left: &Document, right: &Document) -> (Document, Document) {
    let (a_prime, b_prime) = left.data.transform(&right.data).unwrap();
    log::trace!("a:{:?},b:{:?}", a_prime, b_prime);

    let data_left = left.data.compose(&b_prime).unwrap();
    let data_right = right.data.compose(&a_prime).unwrap();
    (
        Document {
            data: data_left,
            history: left.history.clone(),
        },
        Document {
            data: data_right,
            history: right.history.clone(),
        },
    )
}

fn split_length_with_interval(length: usize, interval: Interval) -> (Interval, Interval, Interval) {
    let original_interval = Interval::new(0, length);
    let prefix = original_interval.prefix(interval);
    let suffix = original_interval.suffix(interval);
    (prefix, interval, suffix)
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
