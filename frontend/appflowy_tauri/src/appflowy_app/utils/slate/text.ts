import { Editor, Element, Text, Location } from 'slate';
import { TextDelta } from '$app/interfaces/document';

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

export function getRetainRangeBy(editor: Editor) {
  const start = Editor.start(editor, editor.selection!);
  return {
    anchor: { path: [0, 0], offset: 0 },
    focus: start,
  };
}

export function getInsertRangeBy(editor: Editor) {
  const end = Editor.end(editor, editor.selection!);
  const fragment = (editor.children[0] as Element).children;
  const lastIndex = fragment.length - 1;
  const lastNode = fragment[lastIndex] as Text;
  return {
    anchor: end,
    focus: { path: [0, lastIndex], offset: lastNode.text.length },
  };
}
