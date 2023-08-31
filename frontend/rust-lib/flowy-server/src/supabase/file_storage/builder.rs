use std::borrow::Cow;

use anyhow::Error;
use hyper::header::{CACHE_CONTROL, CONTENT_TYPE};
use reqwest::header::IntoHeaderName;
use reqwest::multipart::{Form, Part};
use reqwest::{
  header::{HeaderMap, HeaderValue},
  Body, Client, Method, RequestBuilder,
};
use tokio::fs::File;
use tokio_util::codec::{BytesCodec, FramedRead};
use url::Url;

use flowy_storage::core::StorageObject;

use crate::supabase::file_storage::{DeleteObjects, FileOptions, NewBucket, RequestBody};

pub struct StorageRequestBuilder {
  pub url: Url,
  headers: HeaderMap,
  client: Client,
  method: Method,
  body: RequestBody,
}

impl StorageRequestBuilder {
  pub fn new(url: Url, headers: HeaderMap, client: Client) -> Self {
    Self {
      url,
      headers,
      client,
      method: Method::GET,
      body: RequestBody::Empty,
    }
  }
  pub fn with_header(mut self, key: impl IntoHeaderName, value: HeaderValue) -> Self {
    self.headers.insert(key, value);
    self
  }

  pub fn get_buckets(mut self) -> Self {
    self.method = Method::GET;
    self.url.path_segments_mut().unwrap().push("bucket");
    self
  }

  pub fn create_bucket(mut self, bucket_name: &str) -> Self {
    self.method = Method::POST;
    self
      .headers
      .insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    self.url.path_segments_mut().unwrap().push("bucket");
    let bucket = serde_json::to_string(&NewBucket::new(bucket_name.to_string())).unwrap();
    self.body = RequestBody::Text { text: bucket };
    self
  }

  pub fn delete_object(mut self, bucket_id: &str, object: &str) -> Self {
    self.method = Method::DELETE;
    self
      .headers
      .insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    let delete_objects = DeleteObjects::new(vec![object.to_string()]);
    let text = serde_json::to_string(&delete_objects).unwrap();
    self.body = RequestBody::Text { text };
    self
      .url
      .path_segments_mut()
      .unwrap()
      .push("object")
      .push(bucket_id)
      .push(object);
    self
  }

  pub fn get_object(mut self, bucket_name: &str, object: &str) -> Self {
    self.method = Method::GET;
    self
      .url
      .path_segments_mut()
      .unwrap()
      .push("object")
      .push(bucket_name)
      .push(object);
    self
  }

  pub fn upload_object(mut self, bucket_name: &str, object: StorageObject) -> Self {
    self.method = Method::POST;
    let options = FileOptions::from_mime(object.value.mime_type());
    self.headers.insert(
      CONTENT_TYPE,
      HeaderValue::from_str(&options.content_type).unwrap(),
    );

    self
      .url
      .path_segments_mut()
      .unwrap()
      .push("object")
      .push(bucket_name)
      .push(&object.name);

    self.body = (options, object.value).into();

    self
  }

  pub fn download_object(mut self, bucket_id: &str) -> Self {
    self.method = Method::POST;
    self
      .headers
      .insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    self
      .url
      .path_segments_mut()
      .unwrap()
      .push("object")
      .push(bucket_id);
    self
  }

  pub async fn build(mut self) -> Result<RequestBuilder, Error> {
    let url = self.url.to_string();
    let mut builder = self.client.request(self.method, url);
    match self.body {
      RequestBody::Empty => {},
      RequestBody::File { file_path, options } => {
        self.headers.insert(
          CACHE_CONTROL,
          HeaderValue::from_str(&options.cache_control).unwrap(),
        );
        self.headers.insert(
          "x-upsert",
          HeaderValue::from_str(&options.upsert.to_string()).unwrap(),
        );

        let file = File::open(&file_path).await?;
        let file_body = Body::wrap_stream(FramedRead::new(file, BytesCodec::new()));
        let part = Part::stream(file_body);
        builder = builder.multipart(Form::new().part("", part));
      },
      RequestBody::Bytes { bytes, options } => {
        self.headers.insert(
          CACHE_CONTROL,
          HeaderValue::from_str(&options.cache_control).unwrap(),
        );
        self.headers.insert(
          "x-upsert",
          HeaderValue::from_str(&options.upsert.to_string()).unwrap(),
        );
        let part = Part::bytes(Cow::Owned(bytes.to_vec()));
        builder = builder.multipart(Form::new().part("", part));
      },
      RequestBody::Text { text } => {
        builder = builder.body(text);
      },
    }
    builder = builder.headers(self.headers);
    Ok(builder)
  }
}
