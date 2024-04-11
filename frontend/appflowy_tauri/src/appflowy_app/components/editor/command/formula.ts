import { ReactEditor } from 'slate-react';
import { Editor, Element, Element as SlateElement, NodeEntry, Range, Transforms } from 'slate';
import { EditorInlineNodeType, FormulaNode } from '$app/application/document/document.types';

export function insertFormula(editor: ReactEditor, formula?: string) {
  if (editor.selection) {
    wrapFormula(editor, formula);
  }
}

export function updateFormula(editor: ReactEditor, formula: string) {
  if (isFormulaActive(editor)) {
    Transforms.delete(editor);
    wrapFormula(editor, formula);
  }
}

export function deleteFormula(editor: ReactEditor) {
  if (isFormulaActive(editor)) {
    Transforms.delete(editor);
  }
}

export function wrapFormula(editor: ReactEditor, formula?: string) {
  if (isFormulaActive(editor)) {
    unwrapFormula(editor);
  }

  const { selection } = editor;

  if (!selection) return;
  const isCollapsed = selection && Range.isCollapsed(selection);

  const data = formula || editor.string(selection);
  const formulaElement = {
    type: EditorInlineNodeType.Formula,
    data,
    children: [
      {
        text: '$',
      },
    ],
  };

  if (!isCollapsed) {
    Transforms.delete(editor);
  }

  Transforms.insertNodes(editor, formulaElement, {
    select: true,
  });

  const path = editor.selection?.anchor.path;

  if (path) {
    editor.select(path);
  }
}

export function unwrapFormula(editor: ReactEditor) {
  const [match] = Editor.nodes(editor, {
    match: (n) => !Editor.isEditor(n) && SlateElement.isElement(n) && n.type === EditorInlineNodeType.Formula,
  });

  if (!match) return;

  const [node, path] = match as NodeEntry<FormulaNode>;
  const formula = node.data;
  const range = Editor.range(editor, match[1]);
  const beforePoint = Editor.before(editor, path, { unit: 'character' });

  Transforms.select(editor, range);
  Transforms.delete(editor);

  Transforms.insertText(editor, formula);

  if (!beforePoint) return;
  Transforms.select(editor, {
    anchor: beforePoint,
    focus: {
      ...beforePoint,
      offset: beforePoint.offset + formula.length,
    },
  });
}

export function isFormulaActive(editor: ReactEditor) {
  const [match] = editor.nodes({
    match: (n) => {
      return !Editor.isEditor(n) && Element.isElement(n) && n.type === EditorInlineNodeType.Formula;
    },
  });

  return Boolean(match);
}
