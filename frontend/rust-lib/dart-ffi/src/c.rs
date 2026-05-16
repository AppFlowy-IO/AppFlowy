use byteorder::{BigEndian, ByteOrder};
use std::mem::forget;

pub fn forget_rust(buf: Vec<u8>) -> *const u8 {
  let ptr = buf.as_ptr();
  forget(buf);
  ptr
}

#[allow(unused_attributes)]
#[allow(dead_code)]
pub fn reclaim_rust(ptr: *mut u8, length: u32) {
  unsafe {
    let len: usize = length as usize;
    Vec::from_raw_parts(ptr, len, len);
  }
}

pub fn extend_front_four_bytes_into_bytes(bytes: &[u8]) -> Vec<u8> {
  let mut output = Vec::with_capacity(bytes.len() + 4);
  let mut marker_bytes = [0; 4];
  BigEndian::write_u32(&mut marker_bytes, bytes.len() as u32);
  output.extend_from_slice(&marker_bytes);
  output.extend_from_slice(bytes);
  output
}
