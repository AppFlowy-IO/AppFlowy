use serde::{de, de::Visitor, Deserialize, Deserializer, Serialize, Serializer};
use std::{fmt, fmt::Formatter};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FlowyStr(pub String);

impl FlowyStr {
    ///
    /// # Arguments
    ///
    /// * `delta`: The delta you want to iterate over.
    /// * `interval`: The range for the cursor movement.
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::FlowyStr;
    /// let utf16_len = FlowyStr::from("👋").utf16_len();
    /// assert_eq!(utf16_len, 2);
    /// let bytes_len = String::from("👋").len();
    /// assert_eq!(bytes_len, 4);
    ///         
    /// ```
    /// https://stackoverflow.com/questions/2241348/what-is-unicode-utf-8-utf-16
    pub fn utf16_len(&self) -> usize {
        count_utf16_code_units(&self.0)
    }

    pub fn utf16_code_unit_iter(&self) -> Utf16CodeUnitIterator {
        Utf16CodeUnitIterator::new(self)
    }

    pub fn sub_str(&self, interval: Interval) -> Option<String> {
        let mut iter = Utf16CodeUnitIterator::new(self);
        let mut buf = vec![];
        while let Some((byte, _len)) = iter.next() {
            if iter.utf16_offset >= interval.start && iter.utf16_offset < interval.end {
                buf.extend_from_slice(byte);
            }
        }

        if buf.is_empty() {
            return None;
        }

        match str::from_utf8(&buf) {
            Ok(item) => Some(item.to_owned()),
            Err(_e) => None,
        }
    }

    #[allow(dead_code)]
    fn utf16_code_point_iter(&self) -> FlowyUtf16CodePointIterator {
        FlowyUtf16CodePointIterator::new(self, 0)
    }
}

impl std::ops::Deref for FlowyStr {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::ops::DerefMut for FlowyStr {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl std::convert::From<String> for FlowyStr {
    fn from(s: String) -> Self {
        FlowyStr(s)
    }
}

impl std::convert::From<&str> for FlowyStr {
    fn from(s: &str) -> Self {
        s.to_owned().into()
    }
}

impl std::fmt::Display for FlowyStr {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::ops::Add<&str> for FlowyStr {
    type Output = FlowyStr;

    fn add(self, rhs: &str) -> FlowyStr {
        let new_value = self.0 + rhs;
        new_value.into()
    }
}

impl std::ops::AddAssign<&str> for FlowyStr {
    fn add_assign(&mut self, rhs: &str) {
        self.0 += rhs;
    }
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

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a str")
            }

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

pub struct Utf16CodeUnitIterator<'a> {
    s: &'a FlowyStr,
    byte_offset: usize,
    utf16_offset: usize,
    utf16_count: usize,
}

impl<'a> Utf16CodeUnitIterator<'a> {
    pub fn new(s: &'a FlowyStr) -> Self {
        Utf16CodeUnitIterator {
            s,
            byte_offset: 0,
            utf16_offset: 0,
            utf16_count: 0,
        }
    }
}

impl<'a> Iterator for Utf16CodeUnitIterator<'a> {
    type Item = (&'a [u8], usize);

    fn next(&mut self) -> Option<Self::Item> {
        let _len = self.s.len();
        if self.byte_offset == self.s.len() {
            None
        } else {
            let b = self.s.as_bytes()[self.byte_offset];
            let start = self.byte_offset;
            let end = self.byte_offset + len_utf8_from_first_byte(b);
            if (b as i8) >= -0x40 {
                self.utf16_count += 1;
            }
            if b >= 0xf0 {
                self.utf16_count += 1;
            }

            if self.utf16_count > 0 {
                self.utf16_offset = self.utf16_count - 1;
            }
            self.byte_offset = end;
            let byte = &self.s.as_bytes()[start..end];
            Some((byte, end - start))
        }
    }
}

pub struct FlowyUtf16CodePointIterator<'a> {
    s: &'a FlowyStr,
    offset: usize,
}

impl<'a> FlowyUtf16CodePointIterator<'a> {
    pub fn new(s: &'a FlowyStr, offset: usize) -> Self {
        FlowyUtf16CodePointIterator { s, offset }
    }
}

use crate::core::interval::Interval;
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
    use crate::core::flowy_str::FlowyStr;
    use crate::core::interval::Interval;

    #[test]
    fn flowy_str_code_unit() {
        let size = FlowyStr::from("👋").utf16_len();
        assert_eq!(size, 2);

        let s: FlowyStr = "👋 \n👋".into();
        let output = s.sub_str(Interval::new(0, size)).unwrap();
        assert_eq!(output, "👋");

        let output = s.sub_str(Interval::new(2, 3)).unwrap();
        assert_eq!(output, " ");

        let output = s.sub_str(Interval::new(3, 4)).unwrap();
        assert_eq!(output, "\n");

        let output = s.sub_str(Interval::new(4, 4 + size)).unwrap();
        assert_eq!(output, "👋");
    }

    #[test]
    fn flowy_str_sub_str_in_chinese() {
        let s: FlowyStr = "你好\n😁".into();
        let size = s.utf16_len();
        assert_eq!(size, 5);

        let output1 = s.sub_str(Interval::new(0, 2)).unwrap();
        let output2 = s.sub_str(Interval::new(2, 3)).unwrap();
        let output3 = s.sub_str(Interval::new(3, 5)).unwrap();
        assert_eq!(output1, "你好");
        assert_eq!(output2, "\n");
        assert_eq!(output3, "😁");
    }

    #[test]
    fn flowy_str_sub_str_in_chinese2() {
        let s: FlowyStr = "😁 \n".into();
        let size = s.utf16_len();
        assert_eq!(size, 4);

        let output1 = s.sub_str(Interval::new(0, 3)).unwrap();
        let output2 = s.sub_str(Interval::new(3, 4)).unwrap();
        assert_eq!(output1, "😁 ");
        assert_eq!(output2, "\n");
    }

    #[test]
    fn flowy_str_sub_str_in_english() {
        let s: FlowyStr = "ab".into();
        let size = s.utf16_len();
        assert_eq!(size, 2);

        let output = s.sub_str(Interval::new(0, 2)).unwrap();
        assert_eq!(output, "ab");
    }

    #[test]
    fn flowy_str_utf16_code_point_iter_test1() {
        let s: FlowyStr = "👋😁👋".into();
        let mut iter = s.utf16_code_point_iter();
        assert_eq!(iter.next().unwrap(), "👋".to_string());
        assert_eq!(iter.next().unwrap(), "😁".to_string());
        assert_eq!(iter.next().unwrap(), "👋".to_string());
        assert_eq!(iter.next(), None);
    }

    #[test]
    fn flowy_str_utf16_code_point_iter_test2() {
        let s: FlowyStr = "👋😁👋".into();
        let iter = s.utf16_code_point_iter();
        let result = iter.skip(1).take(1).collect::<String>();
        assert_eq!(result, "😁".to_string());
    }
}
