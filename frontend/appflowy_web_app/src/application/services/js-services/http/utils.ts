export function blobToBytes (blob: Blob): Promise<Uint8Array> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onloadend = () => {
      if (!(reader.result instanceof ArrayBuffer)) {
        reject(new Error('Failed to convert blob to bytes'));
        return;
      }

      resolve(new Uint8Array(reader.result));
    };

    reader.onerror = reject;
    reader.readAsArrayBuffer(blob);
  });
}
