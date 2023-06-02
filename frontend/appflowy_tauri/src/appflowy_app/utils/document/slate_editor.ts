import { BaseElement, BasePoint, Descendant, Editor, Element, Selection, Text } from "slate";
import Delta from "quill-delta";
import { getLineByIndex } from "$app/utils/document/delta";

export function convertToSlateSelection(index: number, length: number, slateValue: Descendant[]){
  if (!slateValue || slateValue.length === 0) return null;
  const texts = (slateValue[0] as BaseElement).children.map((child) => (child as Text).text);
  const anchorIndex = index;
  const focusIndex = index + length;
  let anchorPath: number[] = [];
  let focusPath: number[] = [];
  let anchorOffset = 0;
  let focusOffset = 0;
  let charCount = 0;
  texts.forEach((text, i) => {
    const endOffset = charCount + text.length;
    if (anchorIndex >= charCount && anchorIndex <= endOffset) {
      anchorPath = [0, i];
      anchorOffset = anchorIndex - charCount;
    }
    if (focusIndex >= charCount && focusIndex <= endOffset) {
      focusPath = [0, i];
      focusOffset = focusIndex - charCount;
    }
    charCount += text.length;
  });
  return {
    anchor: {
      path: anchorPath,
      offset: anchorOffset,
    },
    focus: {
      path: focusPath,
      offset: focusOffset,
    },
  };
}

export function converToIndexLength(editor: Editor, range: Selection) {
  if (!range) return null;
  const start = Editor.start(editor, [0, 0]);
  const before = Editor.start(editor, range);
  const after = Editor.end(editor, range);
  const index = Editor.string(editor, {
    anchor: start,
    focus: before,
  }).length;
  const focusIndex = Editor.string(editor, {
    anchor: start,
    focus: after,
  }).length;
  const length = focusIndex - index;
  return { index, length };
}

export function convertToSlateValue(delta: Delta): Descendant[] {
  const ops = delta.ops;
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  const children: Text[] =
    ops.length === 0
      ? [
          {
            text: '',
          },
        ]
      : ops.map((op) => ({
          text: op.insert || '',
          ...op.attributes,
        }));

  return [
    {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      type: 'paragraph',
      children,
    },
  ];
}

export function convertToDelta(slateValue: Descendant[]) {
  const ops = (slateValue[0] as Element).children.map((child) => {
    const { text, ...attributes } = child as Text;
    return {
      insert: text,
      attributes,
    };
  });
  return new Delta(ops);
}

function getBreakLineBeginPoint(editor: Editor, at: Selection): BasePoint | undefined {
  const delta = convertToDelta(editor.children);
  const currentSelection = converToIndexLength(editor, at);
  if (!currentSelection) return;
  const { index } = getLineByIndex(delta, currentSelection.index);
  const selection = convertToSlateSelection(index, 0, editor.children);
  return selection?.anchor;
}

export function indent(editor: Editor, distance: number) {
  const beginPoint = getBreakLineBeginPoint(editor, editor.selection);
  if (!beginPoint) return;
  const emptyStr = "".padStart(distance);

  editor.insertText(emptyStr, {
    at: beginPoint
  });
}

export function outdent(editor: Editor, distance: number) {
  const beginPoint = getBreakLineBeginPoint(editor, editor.selection);
  if (!beginPoint) return;
  const afterBeginPoint = Editor.after(editor, beginPoint, {
    distance
  });
  if (!afterBeginPoint) return;
  const deleteChar = Editor.string(editor, {
    anchor: beginPoint,
    focus: afterBeginPoint
  });
  const emptyStr = "".padStart(distance);
  if (deleteChar !== emptyStr) {
    if (distance > 1) {
      outdent(editor, distance - 1);
    }
    return;
  }
  editor.delete({
    at: beginPoint,
    distance
  });
}