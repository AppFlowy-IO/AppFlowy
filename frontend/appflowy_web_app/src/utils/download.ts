export async function downloadFile (url: string, filename?: string): Promise<void> {
  try {
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`Download failed, the download status is: ${response.status}`);
    }

    const blob = await response.blob();

    const anchor = document.createElement('a');
    const blobUrl = window.URL.createObjectURL(blob);

    anchor.href = blobUrl;

    anchor.download = filename || url.split('/').pop() || 'download';

    document.body.appendChild(anchor);
    anchor.click();

    document.body.removeChild(anchor);
    window.URL.revokeObjectURL(blobUrl);
  } catch (error) {
    
    return Promise.reject(error);
  }
}
