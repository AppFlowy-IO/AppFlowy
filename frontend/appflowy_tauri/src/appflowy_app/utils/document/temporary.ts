export function isOverlappingPrefix(first: string, second: string): boolean {
  if (first.length === 0 || second.length === 0) return false;
  let i = 0;

  while (i < first.length) {
    const chars = first.substring(i);

    if (chars.length > second.length) return false;
    if (second.startsWith(chars)) return true;
    i++;
  }

  return false;
}
