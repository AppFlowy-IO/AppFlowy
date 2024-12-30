use brotli::{CompressorReader, Decompressor};
use std::io;
use std::io::Read;

pub fn compress(data: &[u8], quality: u32, buffer_size: usize) -> io::Result<Vec<u8>> {
  let mut compressor = CompressorReader::new(data, buffer_size, quality, 22);
  let mut compressed_data = Vec::new();
  compressor.read_to_end(&mut compressed_data)?;
  Ok(compressed_data)
}

pub fn decompress(data: &[u8], buffer_size: usize) -> io::Result<Vec<u8>> {
  let mut decompressor = Decompressor::new(data, buffer_size);
  let mut decompressed_data = Vec::new();
  decompressor.read_to_end(&mut decompressed_data)?;
  Ok(decompressed_data)
}
