use crate::parser::parse_to_html_text::utils::{assert_document_html_eq, assert_document_text_eq};

macro_rules! generate_test_cases {
    ($($block_ty:ident),*) => {
        [
            $(
                (
                    include_str!(concat!("../../assets/json/", stringify!($block_ty), ".json")),
                    include_str!(concat!("../../assets/html/", stringify!($block_ty), ".html")),
                    include_str!(concat!("../../assets/text/", stringify!($block_ty), ".txt")),
                )
            ),*
        ]
    };
}

#[tokio::test]
async fn block_tests() {
  let test_cases = generate_test_cases!(
    heading,
    callout,
    paragraph,
    divider,
    image,
    math_equation,
    code,
    bulleted_list,
    numbered_list,
    todo_list,
    toggle_list,
    quote
  );
  for (json_data, expect_html, expect_text) in test_cases.iter() {
    assert_document_html_eq(json_data, expect_html);
    assert_document_text_eq(json_data, expect_text);
  }
}
