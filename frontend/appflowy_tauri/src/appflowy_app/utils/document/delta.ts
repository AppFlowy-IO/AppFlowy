import Delta from 'quill-delta';

export function getDeltaText(delta: Delta) {
  const text = delta
    .filter((op) => typeof op.insert === 'string')
    .map((op) => op.insert)
    .join('');
  return text;
}

export function caretInTopEdgeByDelta(delta: Delta, index: number) {
  const text = getDeltaText(delta.slice(0, index));
  if (!text) return true;

  const firstLine = text.split('\n')[0];
  return index <= firstLine.length;
}

export function caretInBottomEdgeByDelta(delta: Delta, index: number) {
  const text = getDeltaText(delta.slice(index));

  if (!text) return true;
  return !text.includes('\n');
}

export function getLineByIndex(delta: Delta, index: number) {
  const beforeText = getDeltaText(delta.slice(0, index));
  const afterText = getDeltaText(delta.slice(index));
  const beforeLines = beforeText.split('\n');
  const afterLines = afterText.split('\n');

  const startLineText = beforeLines[beforeLines.length - 1];
  const currentLineText = startLineText + afterLines[0];
  return {
    text: currentLineText,
    index: beforeText.length - startLineText.length,
  };
}

export function transformIndexToPrevLine(delta: Delta, index: number) {
  const text = getDeltaText(delta.slice(0, index));
  const lines = text.split('\n');
  if (lines.length < 2) return 0;
  const prevLineText = lines[lines.length - 2];
  const transformedIndex = index - prevLineText.length - 1;
  return transformedIndex > 0 ? transformedIndex : 0;
}

function getCurrentLineText(delta: Delta, index: number) {
  return getLineByIndex(delta, index).text;
}

export function transformIndexToNextLine(delta: Delta, index: number) {
  const text = getDeltaText(delta);
  const currentLineText = getCurrentLineText(delta, index);
  const transformedIndex = index + currentLineText.length + 1;
  return transformedIndex > text.length ? text.length : transformedIndex;
}

export function getIndexRelativeEnter(delta: Delta, index: number) {
  const text = getDeltaText(delta.slice(0, index));
  const beforeLines = text.split('\n');
  const beforeLineText = beforeLines[beforeLines.length - 1];
  return beforeLineText.length;
}

export function getLastLineIndex(delta: Delta) {
  const text = getDeltaText(delta);
  const lastIndex = text.lastIndexOf('\n');
  return lastIndex === -1 ? 0 : lastIndex + 1;
}

export function getDeltaByRange(
  delta: Delta,
  range: {
    index: number;
    length: number;
  }
) {
  const start = range.index;
  const end = range.index + range.length;
  return new Delta(delta.slice(start, end));
}

export function getBeofreExtentDeltaByRange(
  delta: Delta,
  range: {
    index: number;
    length: number;
  }
) {
  const start = range.index;
  return new Delta(delta.slice(0, start));
}

export function getAfterExtentDeltaByRange(
  delta: Delta,
  range: {
    index: number;
    length: number;
  }
) {
  const start = range.index + range.length;
  return new Delta(delta.slice(start));
}
