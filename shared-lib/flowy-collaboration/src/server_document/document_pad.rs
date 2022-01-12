use crate::{client_document::InitialDocumentText, errors::CollaborateError};
use lib_ot::{core::*, rich_text::RichTextDelta};

pub struct ServerDocument {
    delta: RichTextDelta,
}

impl ServerDocument {
    pub fn new<C: InitialDocumentText>() -> Self { Self::from_delta(C::initial_delta()) }

    pub fn from_delta(delta: RichTextDelta) -> Self { ServerDocument { delta } }

    pub fn from_json(json: &str) -> Result<Self, CollaborateError> {
        let delta = RichTextDelta::from_json(json)?;
        Ok(Self::from_delta(delta))
    }

    pub fn to_json(&self) -> String { self.delta.to_json() }

    pub fn to_bytes(&self) -> Vec<u8> { self.delta.clone().to_bytes().to_vec() }

    pub fn to_plain_string(&self) -> String { self.delta.apply("").unwrap() }

    pub fn delta(&self) -> &RichTextDelta { &self.delta }

    pub fn md5(&self) -> String {
        let bytes = self.to_bytes();
        format!("{:x}", md5::compute(bytes))
    }

    pub fn compose_delta(&mut self, delta: RichTextDelta) -> Result<(), CollaborateError> {
        // tracing::trace!("{} compose {}", &self.delta.to_json(), delta.to_json());
        let composed_delta = self.delta.compose(&delta)?;
        self.delta = composed_delta;
        Ok(())
    }

    pub fn is_empty<C: InitialDocumentText>(&self) -> bool { self.delta == C::initial_delta() }
}
