import { SimpleTableNode } from '@/components/editor/editor.type';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { useEffect, useState } from 'react';
import { Editor, Path, Range } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';

export function useSimpleTable(node: SimpleTableNode) {
  const editor = useSlateStatic();
  const [inCurrentTable, setInCurrentTable] = useState(false);
  const [isIntersection, setIsIntersection] = useState(false);

  useEffect(() => {
    const { onChange } = editor;

    editor.onChange = () => {
      onChange();
      const { selection } = editor;

      if (!selection) return;
      const path = ReactEditor.findPath(editor, node);
      const [start, end] = Editor.edges(editor, selection);
      const isAncestor = Path.isAncestor(path, end.path) && Path.isAncestor(path, start.path);
      const isIntersection = !isAncestor && Range.intersection(selection, Editor.range(editor, path));

      setIsIntersection(!!isIntersection);
      setInCurrentTable(isAncestor);
    };

    return () => {
      editor.onChange = onChange;
    };
  }, [editor, node]);

  useEffect(() => {
    const editorDom = ReactEditor.toDOMNode(editor, editor);

    const handleKeydown = (event: KeyboardEvent) => {
      if (!inCurrentTable) return;

      switch (true) {
        case createHotkey(HOT_KEY_NAME.UP)(event): {
          event.stopPropagation();
          event.preventDefault();
        }

      }

    };

    editorDom.addEventListener('keydown', handleKeydown);

    return () => {
      editorDom.removeEventListener('keydown', handleKeydown);
    };
  }, [editor, inCurrentTable]);

  return {
    isIntersection,
  };
}