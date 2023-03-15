import { TreeNode } from "@/appflowy_app/block_editor/tree_node";
import { BlockContext } from "@/appflowy_app/utils/block";
import { triggerEnter } from "@/appflowy_app/utils/slate/action";
import { triggerHotkey } from "@/appflowy_app/utils/slate/hotkey";
import { useCallback, useContext, useEffect, useMemo, useState } from "react";
import { Transforms, createEditor, Descendant } from 'slate';
import { ReactEditor, withReact } from 'slate-react';
import { debounce } from '../../../utils/tool';

export function useTextBlock({
  node
}: {
  node: TreeNode
}) {
  const [editor] = useState(() => withReact(createEditor()));

  const { blockEditor } = useContext(BlockContext);

  const value = [
    {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      type: 'paragraph',
      children: node.data.content,
    },
  ];

  const debounceSync = useMemo(() => debounce((content) => {
    blockEditor?.sync.update(node.id, {
      paths: ['data', 'content'],
      data: content,
    });
    blockEditor?.sync.sendOps();
  }, 500), [blockEditor, node.id])

  const onChange = useCallback(
    (e: Descendant[]) => {
      if (editor.operations[0].type !== 'set_selection') {
        const content = 'children' in e[0] ? e[0].children : [];
        debounceSync(content);
      } else {
        const newProperties = editor.operations[0].newProperties;
        console.log('===', newProperties, editor.selection)
        blockEditor?.sync.setSelection(node.id, editor.selection);
      }
    },
    [node.id, editor],
  )
  

  const onKeyDownCapture = (event: React.KeyboardEvent<HTMLDivElement>) => {
    switch (event.key) {
      case 'Enter': {
        event.stopPropagation();
        event.preventDefault();
        if (blockEditor) {
          triggerEnter(blockEditor, editor, node);
        }

        return;
      }
    }

    triggerHotkey(event, editor);
  }
  

  useEffect(() => {
    if (!blockEditor) return;
    const { focusBlockId, selection } = blockEditor.selection.getFocusBlockSelection();
    if (focusBlockId !== node.id || !selection) {
      return;
    }
    ReactEditor.focus(editor);
    Transforms.select(editor, selection);
  }, [node.id, editor, blockEditor]);

  return {
    blockEditor,
    editor,
    value,
    onChange,
    onKeyDownCapture
  }
}