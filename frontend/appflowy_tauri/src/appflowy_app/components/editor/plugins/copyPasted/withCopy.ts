import { ReactEditor } from 'slate-react';
import { Editor, Element, Range } from 'slate';

export function withCopy(editor: ReactEditor) {
  const { setFragmentData } = editor;

  editor.setFragmentData = (...args) => {
    if (!editor.selection) {
      setFragmentData(...args);
      return;
    }

    // selection is collapsed and the node is an embed, we need to set the data manually
    if (Range.isCollapsed(editor.selection)) {
      const match = Editor.above(editor, {
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
      });
      const node = match ? (match[0] as Element) : undefined;

      if (node && editor.isEmbed(node)) {
        const fragment = editor.getFragment();

        if (fragment.length > 0) {
          const data = args[0];
          const string = JSON.stringify(fragment);
          const encoded = window.btoa(encodeURIComponent(string));

          const dom = ReactEditor.toDOMNode(editor, node);

          data.setData(`application/x-slate-fragment`, encoded);
          data.setData(`text/html`, dom.innerHTML);
        }
      }
    }

    setFragmentData(...args);
  };

  return editor;
}
