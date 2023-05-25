import { Editor, Element, Location, Text, Range } from 'slate';
import { SelectionPoint, TextDelta, TextSelection } from '$app/interfaces/document';
import * as Y from 'yjs';
import { getDeltaFromSlateNodes } from '$app/utils/document/blocks/common';

export function getDelta(editor: Editor, at: Location): TextDelta[] {
  const baseElement = Editor.fragment(editor, at)[0] as Element;
  return baseElement.children.map((item) => {
    const { text, ...attributes } = item as Text;
    return {
      insert: text,
      attributes,
    };
  });
}

export function getBeforeRangeDelta(delta: TextDelta[], range: TextSelection): TextDelta[] {
  const anchor = Range.start(range);
  const sliceNodes = delta.slice(0, anchor.path[1] + 1);
  const sliceEnd = sliceNodes[sliceNodes.length - 1];
  const sliceEndText = sliceEnd.insert.slice(0, anchor.offset);
  const sliceEndAttributes = sliceEnd.attributes;
  const sliceEndNode =
    sliceEndText.length > 0
      ? {
          insert: sliceEndText,
          attributes: sliceEndAttributes,
        }
      : null;
  const sliceMiddleNodes = sliceNodes.slice(0, sliceNodes.length - 1);

  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  return [...sliceMiddleNodes, sliceEndNode].filter((item) => item);
}

export function getAfterRangeDelta(delta: TextDelta[], range: TextSelection): TextDelta[] {
  const focus = Range.end(range);
  const sliceNodes = delta.slice(focus.path[1], delta.length);
  const sliceStart = sliceNodes[0];
  const sliceStartText = sliceStart.insert.slice(focus.offset);
  const sliceStartAttributes = sliceStart.attributes;
  const sliceStartNode =
    sliceStartText.length > 0
      ? {
          insert: sliceStartText,
          attributes: sliceStartAttributes,
        }
      : null;
  const sliceMiddleNodes = sliceNodes.slice(1, sliceNodes.length);
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  return [sliceStartNode, ...sliceMiddleNodes].filter((item) => item);
}

export function getRangeDelta(delta: TextDelta[], range: TextSelection): TextDelta[] {
  const anchor = Range.start(range);
  const focus = Range.end(range);
  const sliceNodes = delta.slice(anchor.path[1], focus.path[1] + 1);
  if (anchor.path[1] === focus.path[1]) {
    return sliceNodes.map((item) => {
      const { insert, attributes } = item;
      const text = insert.slice(anchor.offset, focus.offset);
      return {
        insert: text,
        attributes,
      };
    });
  }
  const sliceStart = sliceNodes[0];
  const sliceEnd = sliceNodes[sliceNodes.length - 1];
  const sliceStartText = sliceStart.insert.slice(anchor.offset);
  const sliceEndText = sliceEnd.insert.slice(0, focus.offset);
  const sliceStartAttributes = sliceStart.attributes;
  const sliceEndAttributes = sliceEnd.attributes;
  const sliceStartNode =
    sliceStartText.length > 0
      ? {
          insert: sliceStartText,
          attributes: sliceStartAttributes,
        }
      : null;

  const sliceEndNode =
    sliceEndText.length > 0
      ? {
          insert: sliceEndText,
          attributes: sliceEndAttributes,
        }
      : null;
  const sliceMiddleNodes = sliceNodes.slice(1, sliceNodes.length - 1);

  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  return [sliceStartNode, ...sliceMiddleNodes, sliceEndNode].filter((item) => item);
}
/**
 * get the selection between the beginning of the editor and the point
 * form 0 to point
 * @param editor
 * @param at
 */
export function getBeforeRangeAt(editor: Editor, at: Location) {
  const start = Editor.start(editor, at);
  return {
    anchor: { path: [0, 0], offset: 0 },
    focus: start,
  };
}

/**
 * get the selection between the point and the end of the editor
 * from point to end
 * @param editor
 * @param at
 */
export function getAfterRangeAt(editor: Editor, at: Location) {
  const end = Editor.end(editor, at);
  const fragment = (editor.children[0] as Element).children;
  const lastIndex = fragment.length - 1;
  const lastNode = fragment[lastIndex] as Text;
  return {
    anchor: end,
    focus: { path: [0, lastIndex], offset: lastNode.text.length },
  };
}

/**
 * check if the point is in the beginning of the editor
 * @param editor
 * @param at
 */
export function pointInBegin(editor: Editor, at: Location) {
  const start = Editor.start(editor, at);
  return Editor.before(editor, start) === undefined;
}

/**
 * check if the point is in the end of the editor
 * @param editor
 * @param at
 */
export function pointInEnd(editor: Editor, at: Location) {
  const end = Editor.end(editor, at);
  return Editor.after(editor, end) === undefined;
}

/**
 * get the selection of the beginning of the node
 */
export function getNodeBeginSelection(): TextSelection {
  const point: SelectionPoint = {
    path: [0, 0],
    offset: 0,
  };
  const selection: TextSelection = {
    anchor: clonePoint(point),
    focus: clonePoint(point),
  };
  return selection;
}

export function getEditorEndPoint(editor: Editor): SelectionPoint {
  const fragment = (editor.children[0] as Element).children;
  const lastIndex = fragment.length - 1;
  const lastNode = fragment[lastIndex] as Text;
  return { path: [0, lastIndex], offset: lastNode.text.length };
}

/**
 * get the selection of the end of the node
 * @param delta
 */
export function getNodeEndSelection(delta: TextDelta[]) {
  const len = delta.length;
  const offset = len > 0 ? delta[len - 1].insert.length : 0;

  const cursorPoint: SelectionPoint = {
    path: [0, Math.max(len - 1, 0)],
    offset,
  };

  const selection: TextSelection = {
    anchor: clonePoint(cursorPoint),
    focus: clonePoint(cursorPoint),
  };
  return selection;
}

/**
 * get lines by delta
 * @param delta
 */
export function getLinesByDelta(delta: TextDelta[]): string[] {
  const text = delta.map((item) => item.insert).join('');
  return text.split('\n');
}

/**
 * get the offset of the last line
 * @param delta
 */
export function getLastLineOffsetByDelta(delta: TextDelta[]): number {
  const text = delta.map((item) => item.insert).join('');
  const index = text.lastIndexOf('\n');
  return index === -1 ? 0 : index + 1;
}

/**
 * get the offset of per line beginning
 * @param editor
 */
export function getOffsetOfPerLineBeginning(editor: Editor): number[] {
  const delta = getDeltaFromSlateNodes(editor.children);
  const lines = getLinesByDelta(delta);
  const offsets: number[] = [];
  let offset = 0;
  for (let i = 0; i < lines.length; i++) {
    const lineText = lines[i] + '\n';
    offsets.push(offset);
    offset += lineText.length;
  }
  return offsets;
}

/**
 * get the selection of the end line by offset
 * @param delta
 * @param offset relative offset of the end line
 */
export function getEndLineSelectionByOffset(delta: TextDelta[], offset: number) {
  const lines = getLinesByDelta(delta);
  const endLine = lines[lines.length - 1];
  // if the offset is greater than the length of the end line, set cursor to the end of prev line
  if (offset >= endLine.length) {
    return getNodeEndSelection(delta);
  }

  const textOffset = getLastLineOffsetByDelta(delta) + offset;
  return getSelectionByTextOffset(delta, textOffset);
}

/**
 * get the selection of the start line by offset
 * @param delta
 * @param offset relative offset of the start line
 */
export function getStartLineSelectionByOffset(delta: TextDelta[], offset: number) {
  const lines = getLinesByDelta(delta);
  if (lines.length === 0) {
    return getNodeBeginSelection();
  }
  const startLine = lines[0];
  // if the offset is greater than the length of the end line, set cursor to the end of prev line
  if (offset >= startLine.length) {
    return getSelectionByTextOffset(delta, startLine.length);
  }

  return getSelectionByTextOffset(delta, offset);
}

/**
 * get the selection by text offset
 * @param delta
 * @param offset absolute offset
 */
export function getSelectionByTextOffset(delta: TextDelta[], offset: number) {
  const point = getPointByTextOffset(delta, offset);
  const selection: TextSelection = {
    anchor: clonePoint(point),
    focus: clonePoint(point),
  };
  return selection;
}

/**
 * get the text offset by selection
 * @param delta
 * @param point
 */
export function getTextOffsetBySelection(delta: TextDelta[], point: SelectionPoint) {
  let textOffset = 0;
  for (let i = 0; i < point.path[1]; i++) {
    const item = delta[i];
    textOffset += item.insert.length;
  }
  textOffset += point.offset;
  return textOffset;
}

/**
 * get the point by text offset
 * @param delta
 * @param offset absolute offset
 */
export function getPointByTextOffset(delta: TextDelta[], offset: number): SelectionPoint {
  let textOffset = 0;
  let path: [number, number] = [0, 0];
  let textLength = 0;
  for (let i = 0; i < delta.length; i++) {
    const item = delta[i];
    if (textOffset + item.insert.length >= offset) {
      path = [0, i];
      textLength = offset - textOffset;
      break;
    }
    textOffset += item.insert.length;
  }

  return {
    path,
    offset: textLength,
  };
}

export function clonePoint(point: SelectionPoint): SelectionPoint {
  return {
    path: [...point.path],
    offset: point.offset,
  };
}

export function isSameDelta(referDelta: TextDelta[], delta: TextDelta[]) {
  const ydoc = new Y.Doc();
  const yText = ydoc.getText('1');
  const yTextRefer = ydoc.getText('2');
  yText.applyDelta(delta);
  yTextRefer.applyDelta(referDelta);
  return JSON.stringify(yText.toDelta()) === JSON.stringify(yTextRefer.toDelta());
}

export function getDeltaBeforeSelection(editor: Editor) {
  const selection = editor.selection;
  if (!selection) return;
  const beforeRange = getBeforeRangeAt(editor, selection);
  return getDelta(editor, beforeRange);
}

export function getDeltaAfterSelection(editor: Editor): TextDelta[] | undefined {
  const selection = editor.selection;
  if (!selection) return;
  const afterRange = getAfterRangeAt(editor, selection);
  return getDelta(editor, afterRange);
}

export function getSplitDelta(editor: Editor) {
  // get the retain content
  const retain = getDeltaBeforeSelection(editor) || [];
  // get the insert content
  const insert = getDeltaAfterSelection(editor) || [];
  return { retain, insert };
}

export function getPointOfCurrentLineBeginning(editor: Editor) {
  const { selection } = editor;
  if (!selection) return;
  const delta = getDeltaFromSlateNodes(editor.children);
  const textOffset = getTextOffsetBySelection(delta, selection.anchor as SelectionPoint);
  const offsets = getOffsetOfPerLineBeginning(editor);
  let lineNumber = offsets.findIndex((item) => item > textOffset);
  if (lineNumber === -1) {
    lineNumber = offsets.length - 1;
  } else {
    lineNumber -= 1;
  }

  const lineBeginOffset = offsets[lineNumber];

  const beginPoint = getPointByTextOffset(delta, lineBeginOffset);
  return beginPoint;
}

export function selectionIsForward(selection: TextSelection | null) {
  if (!selection) return false;
  const { anchor, focus } = selection;
  if (!anchor || !focus) return false;
  return anchor.path[1] < focus.path[1] || (anchor.path[1] === focus.path[1] && anchor.offset < focus.offset);
}
