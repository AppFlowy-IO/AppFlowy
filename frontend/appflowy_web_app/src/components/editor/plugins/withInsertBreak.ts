import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { ReactEditor } from 'slate-react';

export function withInsertBreak (editor: ReactEditor) {
  const { insertBreak } = editor;

  editor.insertBreak = () => {
    if ((editor as YjsEditor).readOnly) {
      insertBreak();
      return;
    }

    CustomEditor.insertBreak(editor as YjsEditor);
  };

  return editor;
}
