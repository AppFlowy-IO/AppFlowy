export async function readImage(url: string) {
  const { BaseDirectory, readBinaryFile } = await import('@tauri-apps/api/fs');

  try {
    const data = await readBinaryFile(url, { dir: BaseDirectory.AppLocalData });
    const type = url.split('.').pop();
    const blob = new Blob([data], {
      type: `image/${type}`,
    });

    return URL.createObjectURL(blob);
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function readCoverImageUrls(): Promise<{
  images: { url: string }[];
}> {
  const { BaseDirectory, readTextFile, exists } = await import('@tauri-apps/api/fs');

  try {
    const existDir = await exists('cover/image_urls.json', { dir: BaseDirectory.AppLocalData });

    if (!existDir) {
      return {
        images: [],
      };
    }

    const data = await readTextFile('cover/image_urls.json', { dir: BaseDirectory.AppLocalData });

    return JSON.parse(data);
  } catch (e) {
    return Promise.reject(e);
  }
}

export async function writeCoverImageUrls(images: { url: string }[]) {
  const { BaseDirectory, createDir, exists, writeTextFile } = await import('@tauri-apps/api/fs');

  const fileName = 'cover/image_urls.json';
  const jsonString = JSON.stringify({ images });

  try {
    const existDir = await exists('cover', { dir: BaseDirectory.AppLocalData });

    if (!existDir) {
      await createDir('cover', { dir: BaseDirectory.AppLocalData });
    }

    await writeTextFile(fileName, jsonString, { dir: BaseDirectory.AppLocalData });
  } catch (e) {
    return Promise.reject(e);
  }
}

export function convertBlobToBase64(blob: Blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onloadend = () => {
      if (!reader.result) return;

      resolve(reader.result);
    };

    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}

export async function writeImage(file: File) {
  const { BaseDirectory, createDir, exists, writeBinaryFile } = await import('@tauri-apps/api/fs');

  const fileName = `${Date.now()}-${file.name}`;
  const arrayBuffer = await file.arrayBuffer();
  const unit8Array = new Uint8Array(arrayBuffer);

  try {
    const existDir = await exists('images', { dir: BaseDirectory.AppLocalData });

    if (!existDir) {
      await createDir('images', { dir: BaseDirectory.AppLocalData });
    }

    const filePath = 'images/' + fileName;

    await writeBinaryFile(filePath, unit8Array, { dir: BaseDirectory.AppLocalData });
    return filePath;
  } catch (e) {
    return Promise.reject(e);
  }
}
