export async function copyTextToClipboard(text: string) {
  await navigator.clipboard.writeText(text);
}
