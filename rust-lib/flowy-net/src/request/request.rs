use crate::{config::HEADER_TOKEN, errors::ServerError, response::FlowyResponse};
use bytes::Bytes;
use hyper::http;
use protobuf::ProtobufError;
use reqwest::{header::HeaderMap, Client, Method, Response};
use std::{
    convert::{TryFrom, TryInto},
    sync::Arc,
    time::Duration,
};
use tokio::sync::oneshot;

pub trait ResponseMiddleware {
    fn receive_response(&self, token: &Option<String>, response: &FlowyResponse);
}

pub struct HttpRequestBuilder {
    url: String,
    body: Option<Bytes>,
    response: Option<Bytes>,
    headers: HeaderMap,
    method: Method,
    middleware: Vec<Arc<dyn ResponseMiddleware + Send + Sync>>,
}

impl HttpRequestBuilder {
    pub fn new() -> Self {
        Self {
            url: "".to_owned(),
            body: None,
            response: None,
            headers: HeaderMap::new(),
            method: Method::GET,
            middleware: Vec::new(),
        }
    }

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

    pub fn protobuf<T>(self, body: T) -> Result<Self, ServerError>
    where
        T: TryInto<Bytes, Error = ProtobufError>,
    {
        let body: Bytes = body.try_into()?;
        self.bytes(body)
    }

    pub fn bytes(mut self, body: Bytes) -> Result<Self, ServerError> {
        self.body = Some(body);
        Ok(self)
    }

    pub async fn send(self) -> Result<(), ServerError> {
        let _ = self.inner_send().await?;
        Ok(())
    }

    pub async fn response<T>(self) -> Result<T, ServerError>
    where
        T: TryFrom<Bytes, Error = ProtobufError>,
    {
        let builder = self.inner_send().await?;
        match builder.response {
            None => Err(unexpected_empty_payload(&builder.url)),
            Some(data) => Ok(T::try_from(data)?),
        }
    }

    pub async fn option_response<T>(self) -> Result<Option<T>, ServerError>
    where
        T: TryFrom<Bytes, Error = ProtobufError>,
    {
        let result = self.inner_send().await;
        match result {
            Ok(builder) => match builder.response {
                None => Err(unexpected_empty_payload(&builder.url)),
                Some(data) => Ok(Some(T::try_from(data)?)),
            },
            Err(error) => match error.is_record_not_found() {
                true => Ok(None),
                false => Err(error),
            },
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

    async fn inner_send(mut self) -> Result<Self, ServerError> {
        let (tx, rx) = oneshot::channel::<Result<Response, _>>();
        let url = self.url.clone();
        let body = self.body.take();
        let method = self.method.clone();
        let headers = self.headers.clone();

        // reqwest client is not 'Sync' by channel is.
        tokio::spawn(async move {
            let client = default_client();
            let mut builder = client.request(method.clone(), url).headers(headers);
            if let Some(body) = body {
                builder = builder.body(body);
            }

            let response = builder.send().await;
            match tx.send(response) {
                Ok(_) => {},
                Err(e) => {
                    log::error!("[{}] Send http request failed: {:?}", method, e);
                },
            }
        });

        let response = rx.await??;
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
            Some(error) => Err(error),
        }
    }
}

fn unexpected_empty_payload(url: &str) -> ServerError {
    let msg = format!("Request: {} receives unexpected empty payload", url);
    ServerError::payload_none().context(msg)
}

async fn flowy_response_from(original: Response) -> Result<FlowyResponse, ServerError> {
    let bytes = original.bytes().await?;
    let response: FlowyResponse = serde_json::from_slice(&bytes)?;
    Ok(response)
}

#[allow(dead_code)]
async fn get_response_data(original: Response) -> Result<Bytes, ServerError> {
    if original.status() == http::StatusCode::OK {
        let bytes = original.bytes().await?;
        let response: FlowyResponse = serde_json::from_slice(&bytes)?;
        match response.error {
            None => Ok(response.data),
            Some(error) => Err(error),
        }
    } else {
        Err(ServerError::http().context(original))
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
            log::error!("Create reqwest client failed: {}", e);
            reqwest::Client::new()
        },
    }
}
