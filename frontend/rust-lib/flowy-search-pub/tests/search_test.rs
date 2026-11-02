use flowy_search_pub::tantivy_state::DocumentTantivyState;
use uuid::Uuid;

/// The threshold used by the local document search handler.
const SCORE_THRESHOLD: f32 = 0.4;

fn setup() -> (tempfile::TempDir, Uuid, DocumentTantivyState) {
  let dir = tempfile::tempdir().unwrap();
  let workspace_id = Uuid::new_v4();
  let mut state = DocumentTantivyState::new(&workspace_id, dir.path().to_path_buf()).unwrap();
  assert!(state.needs_full_reindex);

  let docs = [
    ("1", "明日映画をみる", "予定"),
    ("2", "明日movie見る", ""),
    ("3", "watch movie tomorrow", ""),
    ("4", "日記", "今日は映画館に行った"),
    ("5", "The Old Man and the Seawhale", ""),
  ];
  for (id, name, content) in docs {
    state
      .add_document(id, Some(content.to_string()), Some(name.to_string()), None)
      .unwrap();
  }
  state.reader.reload().unwrap();
  (dir, workspace_id, state)
}

fn search(state: &DocumentTantivyState, workspace_id: &Uuid, query: &str) -> Vec<String> {
  let mut ids: Vec<String> = state
    .search(workspace_id, query, None, 10, SCORE_THRESHOLD)
    .unwrap()
    .into_iter()
    .map(|item| item.id)
    .collect();
  ids.sort();
  ids
}

#[test]
fn search_japanese_substring_test() {
  let (_dir, workspace_id, state) = setup();
  assert_eq!(search(&state, &workspace_id, "映画"), vec!["1", "4"]);
  assert_eq!(search(&state, &workspace_id, "見る"), vec!["2"]);
  assert_eq!(search(&state, &workspace_id, "をみる"), vec!["1"]);
  assert_eq!(search(&state, &workspace_id, "映画館"), vec!["4"]);
}

#[test]
fn search_japanese_prefix_still_works_test() {
  let (_dir, workspace_id, state) = setup();
  assert_eq!(search(&state, &workspace_id, "明日"), vec!["1", "2"]);
}

#[test]
fn search_japanese_respects_character_order_test() {
  let (_dir, workspace_id, state) = setup();
  assert!(search(&state, &workspace_id, "画映").is_empty());
  assert!(search(&state, &workspace_id, "映画祭").is_empty());
}

#[test]
fn search_latin_word_inside_japanese_text_test() {
  let (_dir, workspace_id, state) = setup();
  assert_eq!(search(&state, &workspace_id, "movie"), vec!["2", "3"]);
  assert_eq!(search(&state, &workspace_id, "Movie"), vec!["2", "3"]);
}

#[test]
fn search_latin_fuzzy_and_prefix_still_works_test() {
  let (_dir, workspace_id, state) = setup();
  // typo
  assert_eq!(search(&state, &workspace_id, "sewhals"), vec!["5"]);
  // prefix
  assert_eq!(search(&state, &workspace_id, "tomor"), vec!["3"]);
}

#[test]
fn search_with_query_syntax_characters_test() {
  let (_dir, workspace_id, state) = setup();
  assert_eq!(search(&state, &workspace_id, "(映画"), vec!["1", "4"]);
  assert_eq!(search(&state, &workspace_id, "\"movie"), vec!["2", "3"]);
  assert!(search(&state, &workspace_id, "  ").is_empty());
}

/// Before the fix, every query below either missed document "1" or matched unrelated
/// documents, because the whole sentence was indexed as a single fuzzy-matched token.
#[test]
fn search_long_japanese_sentence_test() {
  let dir = tempfile::tempdir().unwrap();
  let workspace_id = Uuid::new_v4();
  let mut state = DocumentTantivyState::new(&workspace_id, dir.path().to_path_buf()).unwrap();
  let docs = [
    ("1", "来週の金曜日に友達と映画をみる", ""),
    ("2", "日記", "今日は駅前の映画館に行った"),
    ("3", "買い物リスト", ""),
  ];
  for (id, name, content) in docs {
    state
      .add_document(id, Some(content.to_string()), Some(name.to_string()), None)
      .unwrap();
  }
  state.reader.reload().unwrap();

  assert_eq!(search(&state, &workspace_id, "来週"), vec!["1"]);
  assert_eq!(search(&state, &workspace_id, "映画"), vec!["1", "2"]);
  assert_eq!(search(&state, &workspace_id, "友達"), vec!["1"]);
  assert_eq!(search(&state, &workspace_id, "映画館"), vec!["2"]);
  assert_eq!(search(&state, &workspace_id, "買い物"), vec!["3"]);
}

#[test]
fn search_common_cjk_character_test() {
  // A character that appears in most documents has a low BM25 score, but every match
  // must still pass the score threshold.
  let dir = tempfile::tempdir().unwrap();
  let workspace_id = Uuid::new_v4();
  let mut state = DocumentTantivyState::new(&workspace_id, dir.path().to_path_buf()).unwrap();
  for i in 0..10 {
    let name = if i < 8 {
      format!("映像メモ{i}")
    } else {
      format!("日記{i}")
    };
    state
      .add_document(&i.to_string(), Some(String::new()), Some(name), None)
      .unwrap();
  }
  state.reader.reload().unwrap();
  assert_eq!(
    search(&state, &workspace_id, "映"),
    vec!["0", "1", "2", "3", "4", "5", "6", "7"]
  );
}

#[test]
fn search_does_not_match_across_punctuation_test() {
  let dir = tempfile::tempdir().unwrap();
  let workspace_id = Uuid::new_v4();
  let mut state = DocumentTantivyState::new(&workspace_id, dir.path().to_path_buf()).unwrap();
  state
    .add_document("1", Some(String::new()), Some("映，画".to_string()), None)
    .unwrap();
  state
    .add_document("2", Some(String::new()), Some("映画".to_string()), None)
    .unwrap();
  state.reader.reload().unwrap();
  assert_eq!(search(&state, &workspace_id, "映画"), vec!["2"]);
}

#[test]
fn search_short_latin_word_test() {
  let (_dir, workspace_id, state) = setup();
  // Short words only match as a prefix, without typos.
  assert_eq!(search(&state, &workspace_id, "mo"), vec!["2", "3"]);
  assert!(search(&state, &workspace_id, "xy").is_empty());
}

#[test]
fn reopen_existing_index_test() {
  let (dir, workspace_id, mut state) = setup();
  state.mark_full_reindexed();
  assert!(!state.needs_full_reindex);
  drop(state);
  let state = DocumentTantivyState::new(&workspace_id, dir.path().to_path_buf()).unwrap();
  assert!(!state.needs_full_reindex);
  assert_eq!(search(&state, &workspace_id, "映画"), vec!["1", "4"]);
}

#[test]
fn retry_full_reindex_until_marked_test() {
  let (dir, workspace_id, state) = setup();
  // The reindex was not completed (e.g. resetting the indexed records failed).
  drop(state);
  let state = DocumentTantivyState::new(&workspace_id, dir.path().to_path_buf()).unwrap();
  assert!(state.needs_full_reindex);
}

#[test]
fn remove_legacy_index_test() {
  let dir = tempfile::tempdir().unwrap();
  let workspace_id = Uuid::new_v4();
  let legacy = dir.path().join(workspace_id.to_string()).join("documents");
  std::fs::create_dir_all(&legacy).unwrap();
  std::fs::write(legacy.join("meta.json"), "{}").unwrap();

  let state = DocumentTantivyState::new(&workspace_id, dir.path().to_path_buf()).unwrap();
  assert!(state.needs_full_reindex);
  assert!(!legacy.exists());
}
