import { ReactEditor } from 'slate-react';
import { insertFragment, transFragment } from './utils';
import { convertBlockToJson } from '$app/application/document/document.service';
import { InputType } from '@/services/backend';
import { CustomEditor } from '$app/components/editor/command';
import { Log } from '$app/utils/log';

export function withPasted(editor: ReactEditor) {
  const { insertData } = editor;

  editor.insertData = (data) => {
    const fragment = data.getData('application/x-slate-fragment');

    if (fragment) {
      insertData(data);
      return;
    }

    const html = data.getData('text/html');
    const text = data.getData('text/plain');

    if (!html && !text) {
      insertData(data);
      return;
    }

    void (async () => {
      try {
        const nodes = await convertBlockToJson(html, InputType.Html);

        const htmlTransNoText = nodes.every((node) => {
          return CustomEditor.getNodeTextContent(node).length === 0;
        });

        if (!htmlTransNoText) {
          return editor.insertFragment(nodes);
        }
      } catch (e) {
        Log.warn('pasted html error', e);
        // ignore
      }

      if (text) {
        const nodes = await convertBlockToJson(text, InputType.PlainText);

        editor.insertFragment(nodes);
        return;
      }
    })();
  };

  editor.insertFragment = (fragment, options = {}) => {
    const clonedFragment = transFragment(editor, fragment);

    insertFragment(editor, clonedFragment, options);
  };

  return editor;
}
