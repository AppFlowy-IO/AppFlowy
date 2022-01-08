use serde::{de, de::Visitor, Deserialize, Deserializer, Serialize, Serializer};
use std::{fmt, fmt::Formatter, slice};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FlowyStr(pub String);

impl FlowyStr {
    // https://stackoverflow.com/questions/2241348/what-is-unicode-utf-8-utf-16
    pub fn utf16_size(&self) -> usize { count_utf16_code_units(&self.0) }

    pub fn utf16_code_unit_iter(&self) -> Utf16CodeUnitIterator { Utf16CodeUnitIterator::new(self) }

    pub fn sub_str(&self, interval: Interval) -> String {
        match self.with_interval(interval) {
            None => "".to_owned(),
            Some(s) => s.0,
        }
    }

    pub fn with_interval(&self, interval: Interval) -> Option<FlowyStr> {
        let mut iter = Utf16CodeUnitIterator::new(self);
        let mut buf = vec![];
        while let Some((byte, _len)) = iter.next() {
            if interval.start < iter.code_unit_offset && interval.end >= iter.code_unit_offset {
                buf.extend_from_slice(byte);
            }
        }

        if buf.is_empty() {
            return None;
        }

        match str::from_utf8(&buf) {
            Ok(item) => Some(item.into()),
            Err(_e) => None,
        }
    }

    #[allow(dead_code)]
    fn utf16_code_point_iter(&self) -> FlowyUtf16CodePointIterator { FlowyUtf16CodePointIterator::new(self, 0) }
}

pub struct Utf16CodeUnitIterator<'a> {
    s: &'a FlowyStr,
    bytes_offset: usize,
    code_unit_offset: usize,
    iter_index: usize,
    iter: slice::Iter<'a, u8>,
}

impl<'a> Utf16CodeUnitIterator<'a> {
    pub fn new(s: &'a FlowyStr) -> Self {
        Utf16CodeUnitIterator {
            s,
            bytes_offset: 0,
            code_unit_offset: 0,
            iter_index: 0,
            iter: s.as_bytes().iter(),
        }
    }
}

impl<'a> Iterator for Utf16CodeUnitIterator<'a> {
    type Item = (&'a [u8], usize);

    fn next(&mut self) -> Option<Self::Item> {
        let start = self.bytes_offset;
        let _end = start;

        while let Some(&b) = self.iter.next() {
            self.iter_index += 1;

            let mut code_unit_count = 0;
            if self.bytes_offset > self.iter_index {
                continue;
            }

            if self.bytes_offset == self.iter_index {
                break;
            }

            if (b as i8) >= -0x40 {
                code_unit_count += 1
            }
            if b >= 0xf0 {
                code_unit_count += 1
            }

            self.bytes_offset += len_utf8_from_first_byte(b);
            self.code_unit_offset += code_unit_count;

            if code_unit_count == 1 {
                break;
            }
        }

        if start == self.bytes_offset {
            return None;
        }

        let byte = &self.s.as_bytes()[start..self.bytes_offset];
        Some((byte, self.bytes_offset - start))
    }
}

impl std::ops::Deref for FlowyStr {
    type Target = String;

    fn deref(&self) -> &Self::Target { &self.0 }
}

impl std::ops::DerefMut for FlowyStr {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.0 }
}

impl std::convert::From<String> for FlowyStr {
    fn from(s: String) -> Self { FlowyStr(s) }
}

impl std::convert::From<&str> for FlowyStr {
    fn from(s: &str) -> Self { s.to_owned().into() }
}

impl std::fmt::Display for FlowyStr {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str(&self.0) }
}

impl std::ops::Add<&str> for FlowyStr {
    type Output = FlowyStr;

    fn add(self, rhs: &str) -> FlowyStr {
        let new_value = self.0 + rhs;
        new_value.into()
    }
}

impl std::ops::AddAssign<&str> for FlowyStr {
    fn add_assign(&mut self, rhs: &str) { self.0 += rhs; }
}

impl Serialize for FlowyStr {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.0)
    }
}

impl<'de> Deserialize<'de> for FlowyStr {
    fn deserialize<D>(deserializer: D) -> Result<FlowyStr, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct FlowyStrVisitor;

        impl<'de> Visitor<'de> for FlowyStrVisitor {
            type Value = FlowyStr;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result { formatter.write_str("a str") }

            fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                Ok(s.into())
            }
        }
        deserializer.deserialize_str(FlowyStrVisitor)
    }
}

pub struct FlowyUtf16CodePointIterator<'a> {
    s: &'a FlowyStr,
    offset: usize,
}

impl<'a> FlowyUtf16CodePointIterator<'a> {
    pub fn new(s: &'a FlowyStr, offset: usize) -> Self { FlowyUtf16CodePointIterator { s, offset } }
}

use crate::core::Interval;
use std::str;

impl<'a> Iterator for FlowyUtf16CodePointIterator<'a> {
    type Item = String;

    fn next(&mut self) -> Option<Self::Item> {
        if self.offset == self.s.len() {
            None
        } else {
            let byte = self.s.as_bytes()[self.offset];
            let end = len_utf8_from_first_byte(byte);
            let buf = &self.s.as_bytes()[self.offset..self.offset + end];
            self.offset += end;
            match str::from_utf8(buf) {
                Ok(item) => Some(item.to_string()),
                Err(_e) => None,
            }
        }
    }
}

pub fn count_utf16_code_units(s: &str) -> usize {
    let mut utf16_count = 0;
    for &b in s.as_bytes() {
        if (b as i8) >= -0x40 {
            utf16_count += 1;
        }
        if b >= 0xf0 {
            utf16_count += 1;
        }
    }
    utf16_count
}

/// Given the initial byte of a UTF-8 codepoint, returns the number of
/// bytes required to represent the codepoint.
/// RFC reference : https://tools.ietf.org/html/rfc3629#section-4
pub fn len_utf8_from_first_byte(b: u8) -> usize {
    match b {
        b if b < 0x80 => 1,
        b if b < 0xe0 => 2,
        b if b < 0xf0 => 3,
        _ => 4,
    }
}

#[cfg(test)]
mod tests {
    use crate::core::{FlowyStr, Interval};

    #[test]
    fn flowy_str_utf16_code_point_iter_test1() {
        let s: FlowyStr = "👋😁👋😁".into();
        let mut iter = s.utf16_code_point_iter();
        assert_eq!(iter.next().unwrap(), "👋".to_string());
        assert_eq!(iter.next().unwrap(), "😁".to_string());
        assert_eq!(iter.next().unwrap(), "👋".to_string());
        assert_eq!(iter.next().unwrap(), "😁".to_string());
        assert_eq!(iter.next(), None);
    }

    #[test]
    fn flowy_str_utf16_code_point_iter_test2() {
        let s: FlowyStr = "👋👋😁😁👋👋".into();
        let iter = s.utf16_code_point_iter();
        let result = iter.skip(2).take(2).collect::<String>();
        assert_eq!(result, "😁😁".to_string());
    }

    #[test]
    fn flowy_str_code_unit_test() {
        let s: FlowyStr = "👋 \n👋".into();
        let output = s.with_interval(Interval::new(0, 2)).unwrap().0;
        assert_eq!(output, "👋");

        let output = s.with_interval(Interval::new(2, 3)).unwrap().0;
        assert_eq!(output, " ");

        let output = s.with_interval(Interval::new(3, 4)).unwrap().0;
        assert_eq!(output, "\n");

        let output = s.with_interval(Interval::new(4, 6)).unwrap().0;
        assert_eq!(output, "👋");
    }
}
