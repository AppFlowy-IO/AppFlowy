import { ReactEditor } from 'slate-react';
import { Editor, Element as SlateElement, Range, Transforms } from 'slate';
import { EditorInlineNodeType } from '$app/application/document/document.types';

export function insertFormula(editor: ReactEditor, formula?: string) {
  if (editor.selection) {
    wrapFormula(editor, formula);
  }
}

export function updateFormula(editor: ReactEditor, formula: string) {
  if (isFormulaActive(editor)) {
    Transforms.delete(editor);
    insertFormula(editor, formula);
  }
}

export function wrapFormula(editor: ReactEditor, formula?: string) {
  if (isFormulaActive(editor)) {
    unwrapFormula(editor);
  }

  const { selection } = editor;
  const isCollapsed = selection && Range.isCollapsed(selection);

  const formulaElement = {
    type: EditorInlineNodeType.Formula,
    data: true,
    children: isCollapsed
      ? [
          {
            text: formula || '',
          },
        ]
      : [],
  };

  if (isCollapsed) {
    Transforms.insertNodes(editor, formulaElement);
  } else {
    Transforms.wrapNodes(editor, formulaElement, { split: true });
    Transforms.collapse(editor, { edge: 'end' });
  }
}

export function unwrapFormula(editor: ReactEditor) {
  Transforms.unwrapNodes(editor, {
    match: (n) => !Editor.isEditor(n) && SlateElement.isElement(n) && n.type === EditorInlineNodeType.Formula,
  });
}

export function isFormulaActive(editor: ReactEditor) {
  const [node] = Editor.nodes(editor, {
    match: (n) => !Editor.isEditor(n) && SlateElement.isElement(n) && n.type === EditorInlineNodeType.Formula,
  });

  return !!node;
}
