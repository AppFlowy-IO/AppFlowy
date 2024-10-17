import { md5 } from 'js-md5';

export async function calculateMd5 (file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    const chunkSize = 1_000_000; // Match Rust version's buffer size
    let cursor = 0;
    const md5Hash = md5.create();

    reader.onload = (e: ProgressEvent<FileReader>) => {
      if (e.target?.result instanceof ArrayBuffer) {
        md5Hash.update(new Uint8Array(e.target.result));
        cursor += e.target.result.byteLength;

        if (cursor < file.size) {
          readNextChunk();
        } else {
          const hashBuffer = md5Hash.arrayBuffer();
          const hashBase64 = btoa(String.fromCharCode(...new Uint8Array(hashBuffer)));

          resolve(hashBase64);
        }
      }
    };

    reader.onerror = (error) => {
      reject(error);
    };

    function readNextChunk () {
      const slice = file.slice(cursor, cursor + chunkSize);

      reader.readAsArrayBuffer(slice);
    }

    readNextChunk();
  });
}