use crate::derive_cache::*;
use flowy_ast::{Ctxt, TyInfo};

pub fn ident_category(ident: &syn::Ident) -> TypeCategory {
    let ident_str: &str = &ident.to_string();
    category_from_str(ident_str)
}

pub(crate) fn get_member_ident<'a>(ctxt: &Ctxt, member: &'a syn::Member) -> Option<&'a syn::Ident> {
    if let syn::Member::Named(ref ident) = member {
        Some(ident)
    } else {
        ctxt.error_spanned_by(member, "Unsupported member, shouldn't be self.0".to_string());
        None
    }
}

pub fn assert_bracket_ty_is_some(ctxt: &Ctxt, ty_info: &TyInfo) {
    if ty_info.bracket_ty_info.is_none() {
        ctxt.error_spanned_by(ty_info.ty, "Invalid bracketed type when gen de token steam".to_string());
    }
}
