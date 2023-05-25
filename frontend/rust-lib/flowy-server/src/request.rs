use std::{sync::Arc, time::Duration};

use bytes::Bytes;
use hyper::http;
use reqwest::{header::HeaderMap, Client, Method, Response};
use tokio::sync::oneshot;

use flowy_error::{internal_error, FlowyError};

use crate::response::HttpResponse;
use crate::self_host::configuration::HEADER_TOKEN;

pub trait ResponseMiddleware {
  fn receive_response(&self, token: &Option<String>, response: &HttpResponse);
}

pub struct HttpRequestBuilder {
  url: String,
  body: Option<Bytes>,
  response: Option<Bytes>,
  headers: HeaderMap,
  method: Method,
  middleware: Vec<Arc<dyn ResponseMiddleware + Send + Sync>>,
}

impl std::default::Default for HttpRequestBuilder {
  fn default() -> Self {
    Self {
      url: "".to_owned(),
      body: None,
      response: None,
      headers: HeaderMap::new(),
      method: Method::GET,
      middleware: Vec::new(),
    }
  }
}

impl HttpRequestBuilder {
  pub fn new() -> Self {
    HttpRequestBuilder::default()
  }

  #[allow(dead_code)]
  pub fn middleware<T>(mut self, middleware: Arc<T>) -> Self
  where
    T: 'static + ResponseMiddleware + Send + Sync,
  {
    self.middleware.push(middleware);
    self
  }

  pub fn get(mut self, url: &str) -> Self {
    self.url = url.to_owned();
    self.method = Method::GET;
    self
  }

  pub fn post(mut self, url: &str) -> Self {
    self.url = url.to_owned();
    self.method = Method::POST;
    self
  }

  pub fn patch(mut self, url: &str) -> Self {
    self.url = url.to_owned();
    self.method = Method::PATCH;
    self
  }

  pub fn delete(mut self, url: &str) -> Self {
    self.url = url.to_owned();
    self.method = Method::DELETE;
    self
  }

  pub fn header(mut self, key: &'static str, value: &str) -> Self {
    self.headers.insert(key, value.parse().unwrap());
    self
  }

  pub fn json<T>(self, body: T) -> Result<Self, FlowyError>
  where
    T: serde::Serialize,
  {
    let bytes = Bytes::from(serde_json::to_vec(&body).map_err(internal_error)?);
    self.bytes(bytes)
  }

  pub fn bytes(mut self, body: Bytes) -> Result<Self, FlowyError> {
    self.body = Some(body);
    Ok(self)
  }

  pub async fn send(self) -> Result<(), FlowyError> {
    let _ = self.inner_send().await?;
    Ok(())
  }

  pub async fn response<T>(self) -> Result<T, FlowyError>
  where
    T: serde::de::DeserializeOwned,
  {
    let builder = self.inner_send().await?;
    match builder.response {
      None => Err(unexpected_empty_payload(&builder.url)),
      Some(data) => serde_json::from_slice(&data).map_err(internal_error),
    }
  }

  fn token(&self) -> Option<String> {
    match self.headers.get(HEADER_TOKEN) {
      None => None,
      Some(header) => match header.to_str() {
        Ok(val) => Some(val.to_owned()),
        Err(_) => None,
      },
    }
  }

  async fn inner_send(mut self) -> Result<Self, FlowyError> {
    let (tx, rx) = oneshot::channel::<Result<Response, _>>();
    let url = self.url.clone();
    let body = self.body.take();
    let method = self.method.clone();
    let headers = self.headers.clone();

    // reqwest client is not 'Sync' but channel is.
    tokio::spawn(async move {
      let client = default_client();
      let mut builder = client.request(method.clone(), url).headers(headers);
      if let Some(body) = body {
        builder = builder.body(body);
      }

      let response = builder.send().await;
      let _ = tx.send(response);
    });

    let response = rx.await.map_err(internal_error)?.map_err(internal_error)?;
    tracing::trace!("Http Response: {:?}", response);
    let flowy_response = flowy_response_from(response).await?;
    let token = self.token();
    self.middleware.iter().for_each(|middleware| {
      middleware.receive_response(&token, &flowy_response);
    });
    match flowy_response.error {
      None => {
        self.response = Some(flowy_response.data);
        Ok(self)
      },
      Some(error) => Err(FlowyError::new(error.code, &error.msg)),
    }
  }
}

fn unexpected_empty_payload(url: &str) -> FlowyError {
  let msg = format!("Request: {} receives unexpected empty payload", url);
  FlowyError::payload_none().context(msg)
}

async fn flowy_response_from(original: Response) -> Result<HttpResponse, FlowyError> {
  let bytes = original.bytes().await.map_err(internal_error)?;
  let response: HttpResponse = serde_json::from_slice(&bytes).map_err(internal_error)?;
  Ok(response)
}

#[allow(dead_code)]
async fn get_response_data(original: Response) -> Result<Bytes, FlowyError> {
  if original.status() == http::StatusCode::OK {
    let bytes = original.bytes().await.map_err(internal_error)?;
    let response: HttpResponse = serde_json::from_slice(&bytes).map_err(internal_error)?;
    match response.error {
      None => Ok(response.data),
      Some(error) => Err(FlowyError::new(error.code, &error.msg)),
    }
  } else {
    Err(FlowyError::http().context(original))
  }
}

fn default_client() -> Client {
  let result = reqwest::Client::builder()
    .connect_timeout(Duration::from_millis(500))
    .timeout(Duration::from_secs(5))
    .build();

  match result {
    Ok(client) => client,
    Err(e) => {
      tracing::error!("Create reqwest client failed: {}", e);
      reqwest::Client::new()
    },
  }
}
