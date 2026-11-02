use std::iter::Peekable;
use std::str::CharIndices;
use tantivy::tokenizer::{
  LowerCaser, RemoveLongFilter, TextAnalyzer, Token, TokenStream, Tokenizer,
};

pub const CJK_AWARE_TOKENIZER: &str = "cjk_aware";

/// Analyzer used for the searchable text fields and for parsing search queries.
pub fn cjk_aware_analyzer() -> TextAnalyzer {
  TextAnalyzer::builder(CjkAwareTokenizer::default())
    .filter(RemoveLongFilter::limit(40))
    .filter(LowerCaser)
    .build()
}

/// Returns true for Chinese, Japanese and Korean characters. These scripts are written
/// without spaces between words, so each character is indexed as its own token.
pub fn is_cjk(c: char) -> bool {
  matches!(c as u32,
    0x1100..=0x11FF     // Hangul Jamo
    | 0x3005..=0x3007   // 々 〆 〇
    | 0x3040..=0x30FF   // Hiragana, Katakana
    | 0x3130..=0x318F   // Hangul Compatibility Jamo
    | 0x31F0..=0x31FF   // Katakana Phonetic Extensions
    | 0x3400..=0x4DBF   // CJK Unified Ideographs Extension A
    | 0x4E00..=0x9FFF   // CJK Unified Ideographs
    | 0xA960..=0xA97F   // Hangul Jamo Extended-A
    | 0xAC00..=0xD7AF   // Hangul Syllables
    | 0xD7B0..=0xD7FF   // Hangul Jamo Extended-B
    | 0xF900..=0xFAFF   // CJK Compatibility Ideographs
    | 0xFF66..=0xFF9F   // Halfwidth Katakana
    | 0x20000..=0x3FFFF // CJK Unified Ideographs Extension B and later
  )
}

/// Splits text into tokens:
/// - every CJK character becomes a single token, so a phrase query over consecutive
///   characters matches any substring (e.g. "映画" in "明日映画をみる");
/// - other runs of alphanumeric characters become one token (e.g. "movie" in "明日movie見る");
/// - everything else is a separator. A separator leaves a gap in the token positions, so a
///   phrase query never matches across it (e.g. "映画" does not match "映，画").
#[derive(Clone, Default)]
pub struct CjkAwareTokenizer {
  token: Token,
}

pub struct CjkAwareTokenStream<'a> {
  text: &'a str,
  chars: Peekable<CharIndices<'a>>,
  token: &'a mut Token,
}

impl Tokenizer for CjkAwareTokenizer {
  type TokenStream<'a> = CjkAwareTokenStream<'a>;

  fn token_stream<'a>(&'a mut self, text: &'a str) -> CjkAwareTokenStream<'a> {
    self.token.reset();
    CjkAwareTokenStream {
      text,
      chars: text.char_indices().peekable(),
      token: &mut self.token,
    }
  }
}

impl CjkAwareTokenStream<'_> {
  fn next_position(&mut self, after_separator: bool) {
    // `Token::reset` sets the position to usize::MAX, so the first token gets position 0.
    self.token.position = if self.token.position == usize::MAX {
      0
    } else {
      self.token.position + 1 + usize::from(after_separator)
    };
  }
}

impl TokenStream for CjkAwareTokenStream<'_> {
  fn advance(&mut self) -> bool {
    self.token.text.clear();

    let mut after_separator = false;
    while let Some((offset, c)) = self.chars.next() {
      if is_cjk(c) {
        self.next_position(after_separator);
        self.token.offset_from = offset;
        self.token.offset_to = offset + c.len_utf8();
        self.token.text.push(c);
        return true;
      }

      if c.is_alphanumeric() {
        self.next_position(after_separator);
        let mut end = offset + c.len_utf8();
        while let Some(&(next_offset, next)) = self.chars.peek() {
          if is_cjk(next) || !next.is_alphanumeric() {
            break;
          }
          end = next_offset + next.len_utf8();
          self.chars.next();
        }
        self.token.offset_from = offset;
        self.token.offset_to = end;
        self.token.text.push_str(&self.text[offset..end]);
        return true;
      }

      after_separator = true;
    }

    false
  }

  fn token(&self) -> &Token {
    self.token
  }

  fn token_mut(&mut self) -> &mut Token {
    self.token
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  fn tokens(text: &str) -> Vec<(String, usize)> {
    let mut analyzer = cjk_aware_analyzer();
    let mut stream = analyzer.token_stream(text);
    let mut tokens = vec![];
    while stream.advance() {
      let token = stream.token();
      tokens.push((token.text.clone(), token.position));
    }
    tokens
  }

  #[test]
  fn split_cjk_into_characters_test() {
    assert_eq!(
      tokens("明日映画をみる"),
      vec![
        ("明".to_string(), 0),
        ("日".to_string(), 1),
        ("映".to_string(), 2),
        ("画".to_string(), 3),
        ("を".to_string(), 4),
        ("み".to_string(), 5),
        ("る".to_string(), 6),
      ]
    );
  }

  #[test]
  fn split_mixed_cjk_and_latin_test() {
    let texts: Vec<String> = tokens("明日Movie見る").into_iter().map(|t| t.0).collect();
    assert_eq!(texts, vec!["明", "日", "movie", "見", "る"]);
  }

  #[test]
  fn split_latin_words_test() {
    let texts: Vec<String> = tokens("Watch movie, tomorrow!")
      .into_iter()
      .map(|t| t.0)
      .collect();
    assert_eq!(texts, vec!["watch", "movie", "tomorrow"]);
  }

  #[test]
  fn separator_leaves_position_gap_test() {
    assert_eq!(
      tokens("映，画 a"),
      vec![
        ("映".to_string(), 0),
        ("画".to_string(), 2),
        ("a".to_string(), 4),
      ]
    );
  }

  #[test]
  fn split_hangul_jamo_extended_test() {
    let texts: Vec<String> = tokens("\u{A960}\u{D7B0}")
      .into_iter()
      .map(|t| t.0)
      .collect();
    assert_eq!(texts, vec!["\u{A960}", "\u{D7B0}"]);
  }

  #[test]
  fn split_korean_and_katakana_test() {
    let texts: Vec<String> = tokens("한국 コーヒー").into_iter().map(|t| t.0).collect();
    assert_eq!(texts, vec!["한", "국", "コ", "ー", "ヒ", "ー"]);
  }
}
