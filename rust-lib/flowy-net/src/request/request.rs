use crate::{
    errors::{Code, ServerError},
    response::FlowyResponse,
};
use bytes::Bytes;
use hyper::http;
use protobuf::ProtobufError;
use reqwest::{Client, Method, Response};
use std::{
    convert::{TryFrom, TryInto},
    time::Duration,
};
use tokio::sync::oneshot;

pub struct HttpRequestBuilder {
    url: String,
    body: Option<Bytes>,
    response: Option<Bytes>,
    method: Method,
}

impl HttpRequestBuilder {
    fn new(url: &str) -> Self {
        Self {
            url: url.to_owned(),
            body: None,
            response: None,
            method: Method::GET,
        }
    }

    pub fn get(url: &str) -> Self {
        let mut builder = Self::new(url);
        builder.method = Method::GET;
        builder
    }

    pub fn post(url: &str) -> Self {
        let mut builder = Self::new(url);
        builder.method = Method::POST;
        builder
    }

    pub fn protobuf<T1>(mut self, body: T1) -> Result<Self, ServerError>
    where
        T1: TryInto<Bytes, Error = ProtobufError>,
    {
        let body: Bytes = body.try_into()?;
        self.body = Some(body);
        Ok(self)
    }

    pub async fn send(mut self) -> Result<Self, ServerError> {
        let (tx, rx) = oneshot::channel::<Result<Response, _>>();
        let url = self.url.clone();
        let body = self.body.take();
        let method = self.method.clone();

        // reqwest client is not 'Sync' by channel is.
        tokio::spawn(async move {
            let client = default_client();
            let mut builder = client.request(method, url);

            if let Some(body) = body {
                builder = builder.body(body);
            }

            let response = builder.send().await;
            tx.send(response);
        });

        let response = rx.await??;
        let data = get_response_data(response).await?;
        self.response = Some(data);
        Ok(self)
    }

    pub fn response<T2>(mut self) -> Result<T2, ServerError>
    where
        T2: TryFrom<Bytes, Error = ProtobufError>,
    {
        let data = self.response.take();
        match data {
            None => {
                let msg = format!("Request: {} receives unexpected empty body", self.url);
                Err(ServerError::payload_none().with_msg(msg))
            },
            Some(data) => Ok(T2::try_from(data)?),
        }
    }
}

#[allow(dead_code)]
pub async fn http_post<T1, T2>(url: &str, data: T1) -> Result<T2, ServerError>
where
    T1: TryInto<Bytes, Error = ProtobufError>,
    T2: TryFrom<Bytes, Error = ProtobufError>,
{
    let body: Bytes = data.try_into()?;
    let url = url.to_owned();
    let (tx, rx) = oneshot::channel::<Result<Response, _>>();

    // reqwest client is not 'Sync' by channel is.
    tokio::spawn(async move {
        let client = default_client();
        let response = client.post(&url).body(body).send().await;
        tx.send(response);
    });

    let response = rx.await??;
    let data = get_response_data(response).await?;
    Ok(T2::try_from(data)?)
}

async fn get_response_data(original: Response) -> Result<Bytes, ServerError> {
    if original.status() == http::StatusCode::OK {
        let bytes = original.bytes().await?;
        let response: FlowyResponse = serde_json::from_slice(&bytes)?;
        match response.error {
            None => Ok(response.data),
            Some(error) => Err(error),
        }
    } else {
        Err(ServerError::http().with_msg(original))
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
