use quote::ToTokens;
use std::{cell::RefCell, fmt::Display, thread};

#[derive(Default)]
pub struct ASTResult {
  errors: RefCell<Option<Vec<syn::Error>>>,
}

impl ASTResult {
  pub fn new() -> Self {
    ASTResult {
      errors: RefCell::new(Some(Vec::new())),
    }
  }

  pub fn error_spanned_by<A: ToTokens, T: Display>(&self, obj: A, msg: T) {
    self
      .errors
      .borrow_mut()
      .as_mut()
      .unwrap()
      .push(syn::Error::new_spanned(obj.into_token_stream(), msg));
  }

  pub fn syn_error(&self, err: syn::Error) {
    self.errors.borrow_mut().as_mut().unwrap().push(err);
  }

  pub fn check(self) -> Result<(), Vec<syn::Error>> {
    let errors = self.errors.borrow_mut().take().unwrap();
    match errors.len() {
      0 => Ok(()),
      _ => Err(errors),
    }
  }
}

impl Drop for ASTResult {
  fn drop(&mut self) {
    if !thread::panicking() && self.errors.borrow().is_some() {
      panic!("forgot to check for errors");
    }
  }
}
