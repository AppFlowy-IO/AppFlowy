use serde::{de, de::Visitor, Deserialize, Deserializer, Serialize, Serializer};
use std::{fmt, fmt::Formatter};

/// [OTString] uses [String] as its inner container.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OTString(pub String);

impl OTString {
    /// Returns the number of UTF-16 code units in this string.
    ///
    /// The length of strings behaves differently in different languages. For example: [Dart] string's
    /// length is calculated with UTF-16 code units. The method [utf16_len] returns the length of a
    /// String in UTF-16 code units.
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::OTString;
    /// let utf16_len = OTString::from("👋").utf16_len();
    /// assert_eq!(utf16_len, 2);
    /// let bytes_len = String::from("👋").len();
    /// assert_eq!(bytes_len, 4);
    ///         
    /// ```
    pub fn utf16_len(&self) -> usize {
        count_utf16_code_units(&self.0)
    }

    pub fn utf16_iter(&self) -> Utf16CodeUnitIterator {
        Utf16CodeUnitIterator::new(self)
    }

    /// Returns a new string with the given [Interval]
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{OTString, Interval};
    /// let s: OTString = "你好\n😁".into();
    /// assert_eq!(s.utf16_len(), 5);
    /// let output1 = s.sub_str(Interval::new(0, 2)).unwrap();
    /// assert_eq!(output1, "你好");
    ///
    /// let output2 = s.sub_str(Interval::new(2, 3)).unwrap();
    /// assert_eq!(output2, "\n");
    ///
    /// let output3 = s.sub_str(Interval::new(3, 5)).unwrap();
    /// assert_eq!(output3, "😁");
    /// ```
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

    /// Return a new string with the given [Interval]
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::OTString;
    /// let s: OTString = "👋😁👋".into();    ///
    /// let mut iter = s.utf16_code_point_iter();
    /// assert_eq!(iter.next().unwrap(), "👋".to_string());
    /// assert_eq!(iter.next().unwrap(), "😁".to_string());
    /// assert_eq!(iter.next().unwrap(), "👋".to_string());
    /// assert_eq!(iter.next(), None);
    ///
    /// let s: OTString = "👋12ab一二👋".into();    ///
    /// let mut iter = s.utf16_code_point_iter();
    /// assert_eq!(iter.next().unwrap(), "👋".to_string());
    /// assert_eq!(iter.next().unwrap(), "1".to_string());
    /// assert_eq!(iter.next().unwrap(), "2".to_string());
    ///
    /// assert_eq!(iter.skip(OTString::from("ab一二").utf16_len()).next().unwrap(), "👋".to_string());
    /// ```
    #[allow(dead_code)]
    pub fn utf16_code_point_iter(&self) -> OTUtf16CodePointIterator {
        OTUtf16CodePointIterator::new(self, 0)
    }
}

impl std::ops::Deref for OTString {
    type Target = String;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::ops::DerefMut for OTString {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl std::convert::From<String> for OTString {
    fn from(s: String) -> Self {
        OTString(s)
    }
}

impl std::convert::From<&str> for OTString {
    fn from(s: &str) -> Self {
        s.to_owned().into()
    }
}

impl std::fmt::Display for OTString {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::ops::Add<&str> for OTString {
    type Output = OTString;

    fn add(self, rhs: &str) -> OTString {
        let new_value = self.0 + rhs;
        new_value.into()
    }
}

impl std::ops::AddAssign<&str> for OTString {
    fn add_assign(&mut self, rhs: &str) {
        self.0 += rhs;
    }
}

impl Serialize for OTString {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.0)
    }
}

impl<'de> Deserialize<'de> for OTString {
    fn deserialize<D>(deserializer: D) -> Result<OTString, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct OTStringVisitor;

        impl<'de> Visitor<'de> for OTStringVisitor {
            type Value = OTString;

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
        deserializer.deserialize_str(OTStringVisitor)
    }
}

pub struct Utf16CodeUnitIterator<'a> {
    s: &'a OTString,
    byte_offset: usize,
    utf16_offset: usize,
    utf16_count: usize,
}

impl<'a> Utf16CodeUnitIterator<'a> {
    pub fn new(s: &'a OTString) -> Self {
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

pub struct OTUtf16CodePointIterator<'a> {
    s: &'a OTString,
    offset: usize,
}

impl<'a> OTUtf16CodePointIterator<'a> {
    pub fn new(s: &'a OTString, offset: usize) -> Self {
        OTUtf16CodePointIterator { s, offset }
    }
}

use crate::core::interval::Interval;
use std::str;

impl<'a> Iterator for OTUtf16CodePointIterator<'a> {
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
    use crate::core::interval::Interval;
    use crate::core::ot_str::OTString;

    #[test]
    fn flowy_str_code_unit() {
        let size = OTString::from("👋").utf16_len();
        assert_eq!(size, 2);

        let s: OTString = "👋 \n👋".into();
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
    fn flowy_str_sub_str_in_chinese2() {
        let s: OTString = "😁 \n".into();
        let size = s.utf16_len();
        assert_eq!(size, 4);

        let output1 = s.sub_str(Interval::new(0, 3)).unwrap();
        let output2 = s.sub_str(Interval::new(3, 4)).unwrap();
        assert_eq!(output1, "😁 ");
        assert_eq!(output2, "\n");
    }

    #[test]
    fn flowy_str_sub_str_in_english() {
        let s: OTString = "ab".into();
        let size = s.utf16_len();
        assert_eq!(size, 2);

        let output = s.sub_str(Interval::new(0, 2)).unwrap();
        assert_eq!(output, "ab");
    }

    #[test]
    fn flowy_str_utf16_code_point_iter_test2() {
        let s: OTString = "👋😁👋".into();
        let iter = s.utf16_code_point_iter();
        let result = iter.skip(1).take(1).collect::<String>();
        assert_eq!(result, "😁".to_string());
    }
}
