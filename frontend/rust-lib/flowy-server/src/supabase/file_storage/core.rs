use anyhow::{anyhow, Error};
use bytes::Bytes;
use hyper::header::{CACHE_CONTROL, CONTENT_TYPE};
use reqwest::header::IntoHeaderName;
use reqwest::multipart::{Form, Part};
use reqwest::{
  header::{HeaderMap, HeaderValue},
  Body, Client, Method, RequestBuilder,
};
use serde_json::Value;
use tokio::fs::File;
use tokio_util::codec::{BytesCodec, FramedRead};
use url::Url;

use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_storage::core::FileStorageService;
use lib_infra::async_trait::async_trait;

use crate::response::ExtendedResponse;
use crate::supabase::file_storage::{DeleteObjects, FileOptions, NewBucket};

pub struct SupabaseFileStorage {
  url: Url,
  headers: HeaderMap,
  client: Client,
}

impl SupabaseFileStorage {
  pub fn new(config: &SupabaseConfiguration) -> Result<Self, Error> {
    let mut headers = HeaderMap::new();
    let url = format!("{}/storage/v1", config.url);
    let auth = format!("Bearer {}", config.anon_key);

    headers.insert(
      "Authorization",
      HeaderValue::from_str(&auth).expect("Authorization is invalid"),
    );
    headers.insert(
      "apikey",
      HeaderValue::from_str(&config.anon_key).expect("apikey value is invalid"),
    );

    Ok(Self {
      url: Url::parse(&url)?,
      headers,
      client: Client::new(),
    })
  }

  pub fn request(&self) -> FileStorageRequestBuilder {
    FileStorageRequestBuilder::new(self.url.clone(), self.headers.clone(), self.client.clone())
  }
}

pub enum RequestBody {
  Empty,
  File {
    file_path: String,
    options: FileOptions,
  },
  Text {
    text: String,
  },
}

pub struct FileStorageRequestBuilder {
  url: Url,
  headers: HeaderMap,
  client: Client,
  method: Method,
  body: RequestBody,
}

impl FileStorageRequestBuilder {
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

  pub fn upload_object(mut self, bucket_name: &str, object: &str, file_path: &str) -> Self {
    self.method = Method::POST;
    let options = FileOptions::from_file_path(file_path);
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
      .push(object);

    self.body = RequestBody::File {
      file_path: file_path.to_string(),
      options,
    };

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
        let part = Part::stream(file_body).mime_str(&options.content_type)?;
        builder = builder.multipart(Form::new().part(file_path, part));
      },
      RequestBody::Text { text } => {
        builder = builder.body(text);
      },
    }
    builder = builder.headers(self.headers);
    Ok(builder)
  }
}

#[async_trait]
impl FileStorageService for SupabaseFileStorage {
  async fn create_object(&self, object_name: &str, object_path: &str) -> Result<String, Error> {
    let resp: Value = self
      .request()
      .upload_object("data", object_name, object_path)
      .build()
      .await?
      .send()
      .await?
      .get_json()
      .await?;

    let key = resp
      .get("Key")
      .and_then(|v| v.as_str())
      .ok_or(anyhow!("Key not found in response"))?
      .to_string();

    Ok(key)
  }

  async fn delete_object(&self, object_name: &str) -> Result<(), Error> {
    let resp = self
      .request()
      .delete_object("data", object_name)
      .build()
      .await?
      .send()
      .await?
      .success()
      .await?;
    println!("{:?}", resp);
    Ok(())
  }

  async fn get_object(&self, object_name: &str) -> Result<Bytes, Error> {
    let bytes = self
      .request()
      .get_object("data", object_name)
      .build()
      .await?
      .send()
      .await?
      .get_bytes()
      .await?;
    Ok(bytes)
  }
}
