use std::io;
use std::io::Write;
use std::sync::Arc;
use tracing_subscriber::fmt::MakeWriter;

pub struct StreamLog {
  pub sender: Arc<dyn StreamLogSender>,
}

impl<'a> MakeWriter<'a> for StreamLog {
  type Writer = SenderWriter;

  fn make_writer(&'a self) -> Self::Writer {
    SenderWriter {
      sender: self.sender.clone(),
    }
  }
}

pub trait StreamLogSender: Send + Sync {
  fn send(&self, message: &[u8]);
}

pub struct SenderWriter {
  sender: Arc<dyn StreamLogSender>,
}

impl Write for SenderWriter {
  fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
    self.sender.send(buf);
    Ok(buf.len())
  }

  fn flush(&mut self) -> io::Result<()> {
    Ok(())
  }
}
