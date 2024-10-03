import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { isAtBlockStart, isAtBlockEnd, isEntireDocumentSelected } from '@/application/slate-yjs/utils/yjsOperations';
import { TextUnit, Range, EditorFragmentDeletionOptions } from 'slate';
import { ReactEditor } from 'slate-react';
import { TextDeleteOptions } from 'slate/dist/interfaces/transforms/text';

export function withDelete (editor: ReactEditor) {
  const { deleteForward, deleteBackward, delete: deleteText } = editor;

  editor.delete = (options?: TextDeleteOptions) => {
    const { selection } = editor;

    if (!selection) return;

    if (Range.isCollapsed(selection)) {
      deleteText(options);
      return;
    }

    CustomEditor.deleteBlockBackward(editor as YjsEditor, selection);
  };

  editor.deleteFragment = (options?: EditorFragmentDeletionOptions) => {
    const deleteEntireDocument = isEntireDocumentSelected(editor as YjsEditor);

    if (deleteEntireDocument) {
      CustomEditor.deleteEntireDocument(editor as YjsEditor);
      return;
    }

    const { selection } = editor;

    if (!selection) return;
    if (options?.direction === 'backward') {
      CustomEditor.deleteBlockBackward(editor as YjsEditor, selection);
    } else {
      CustomEditor.deleteBlockForward(editor as YjsEditor, selection);
    }
  };

  // Handle `delete` key press
  editor.deleteForward = (unit: TextUnit) => {
    const { selection } = editor;

    if (!selection) {
      return;
    }

    let shouldUseDefaultBehavior = false;

    if (selection && Range.isCollapsed(selection)) {
      shouldUseDefaultBehavior = !isAtBlockEnd(editor, selection.anchor);
    }

    if (shouldUseDefaultBehavior) {
      deleteForward(unit);
      return;
    }

    CustomEditor.deleteBlockForward(editor as YjsEditor, selection);
  };

  // Handle `backspace` key press
  editor.deleteBackward = (unit: TextUnit) => {
    const { selection } = editor;

    if (!selection) {
      return;
    }

    let shouldUseDefaultBehavior = false;

    const isCollapsed = selection && Range.isCollapsed(selection);

    if (isCollapsed) {
      shouldUseDefaultBehavior = !isAtBlockStart(editor, selection.anchor);
    }

    if (shouldUseDefaultBehavior) {
      deleteBackward(unit);
      return;
    }

    CustomEditor.deleteBlockBackward(editor as YjsEditor, selection);
  };

  return editor;
}
