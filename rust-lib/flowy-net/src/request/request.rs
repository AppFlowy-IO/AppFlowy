use crate::errors::NetworkError;
use bytes::Bytes;
use protobuf::Message;
use reqwest::{Client, Response};
use std::{convert::TryFrom, time::Duration};

pub struct FlowyRequest {
    client: Client,
}

impl FlowyRequest {
    pub fn new() -> Self {
        let client = default_client();
        Self { client }
    }

    pub async fn get<T>(&self, url: &str) -> Result<T, NetworkError>
    where
        T: Message,
    {
        let url = url.to_owned();
        let response = self.client.get(&url).send().await?;
        parse_response(response).await
    }

    pub async fn post<T>(&self, url: &str, data: T) -> Result<T, NetworkError>
    where
        T: Message,
    {
        let url = url.to_owned();
        let body = data.write_to_bytes()?;
        let response = self.client.post(&url).body(body).send().await?;
        parse_response(response).await
    }

    pub async fn post_data<T>(&self, url: &str, bytes: Vec<u8>) -> Result<T, NetworkError>
    where
        T: for<'a> TryFrom<&'a Vec<u8>>,
    {
        let url = url.to_owned();
        let response = self.client.post(&url).body(bytes).send().await?;
        let bytes = response.bytes().await?.to_vec();
        let data = T::try_from(&bytes).map_err(|_e| panic!("")).unwrap();
        Ok(data)
    }
}

async fn parse_response<T>(response: Response) -> Result<T, NetworkError>
where
    T: Message,
{
    let bytes = response.bytes().await?;
    parse_bytes(bytes)
}

fn parse_bytes<T>(bytes: Bytes) -> Result<T, NetworkError>
where
    T: Message,
{
    match Message::parse_from_bytes(&bytes) {
        Ok(data) => Ok(data),
        Err(e) => {
            log::error!(
                "Parse bytes for {:?} failed: {}",
                std::any::type_name::<T>(),
                e
            );
            Err(e.into())
        },
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
