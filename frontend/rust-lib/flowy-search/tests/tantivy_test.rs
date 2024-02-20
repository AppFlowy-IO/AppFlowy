use tantivy::collector::TopDocs;
use tantivy::query::QueryParser;
use tantivy::schema::*;
use tantivy::{doc, DocAddress, Index, Score};

#[test]
fn search_folder_test() {
  let mut schema_builder = Schema::builder();
  let id = schema_builder.add_text_field("id", TEXT);
  let title = schema_builder.add_text_field("title", TEXT | STORED);
  let schema = schema_builder.build();

  // Indexing documents
  let index = Index::create_from_tempdir(schema.clone()).unwrap();

  // Here we use a buffer of 100MB that will be split
  // between indexing threads.
  let mut index_writer = index.writer(100_000_000).unwrap();

  // Let's index one documents!
  index_writer
    .add_document(doc!(
        id => "123456789",
        title => "The Old Man and the Seawhale",
    ))
    .unwrap();

  // We need to call .commit() explicitly to force the
  // index_writer to finish processing the documents in the queue,
  // flush the current index to the disk, and advertise
  // the existence of new documents.
  index_writer.commit().unwrap();

  // # Searching
  let reader = index.reader().unwrap();

  let searcher = reader.searcher();

  let mut query_parser = QueryParser::for_index(&index, vec![title]);
  query_parser.set_field_fuzzy(title, true, 2, true);
  let query = query_parser.parse_query("sewhals").unwrap();

  // Perform search.
  // `topdocs` contains the 10 most relevant doc ids, sorted by decreasing scores...
  let top_docs: Vec<(Score, DocAddress)> =
    searcher.search(&query, &TopDocs::with_limit(10)).unwrap();

  for (_score, doc_address) in top_docs {
    // Retrieve the actual content of documents given its `doc_address`.
    let retrieved_doc = searcher.doc(doc_address).unwrap();
    println!("{}", schema.to_json(&retrieved_doc));
  }
}
