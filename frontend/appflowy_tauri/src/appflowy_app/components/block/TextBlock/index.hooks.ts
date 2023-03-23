import { TreeNode } from "@/appflowy_app/block_editor/view/tree_node";
import { triggerHotkey } from "@/appflowy_app/utils/slate/hotkey";
import { useCallback, useContext, useLayoutEffect, useState } from "react";
import { Transforms, createEditor, Descendant } from 'slate';
import { ReactEditor, withReact } from 'slate-react';
import { TextBlockContext } from '$app/utils/slate/context';

export function useTextBlock({
  node,
}: {
  node: TreeNode;
}) {
  const [editor] = useState(() => withReact(createEditor()));

  const { textBlockManager } = useContext(TextBlockContext);

  const value = [
    {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      type: 'paragraph',
      children: node.data.content,
    },
  ];


  const onChange = useCallback(
    (e: Descendant[]) => {
      if (!editor.operations || editor.operations.length === 0) return;
      if (editor.operations[0].type !== 'set_selection') {
        console.log('====text block ==== ', editor.operations)
        const children = 'children' in e[0] ? e[0].children : [];
        textBlockManager?.update(node, ['data', 'content'], children);
      } else {
        const newProperties = editor.operations[0].newProperties;
        textBlockManager?.setSelection(node, editor.selection);
      }
    },
    [node.id, editor],
  );
  

  const onKeyDownCapture = (event: React.KeyboardEvent<HTMLDivElement>) => {
    switch (event.key) {
      case 'Enter': {
        event.stopPropagation();
        event.preventDefault();
        textBlockManager?.splitNode(node, editor);

        return;
      }
    }

    triggerHotkey(event, editor);
  }

  

  const { focusId, selection } = textBlockManager!.selectionManager.getFocusSelection();
  
  editor.children = value;
  Transforms.collapse(editor);

  useLayoutEffect(() => {
    let timer: NodeJS.Timeout;
    if (focusId === node.id && selection) {
      ReactEditor.focus(editor);
      Transforms.select(editor, selection);
      // Use setTimeout to delay setting the selection
      // until Slate has fully loaded and rendered all components and contents,
      // to ensure that the operation succeeds.
      timer = setTimeout(() => {
        Transforms.select(editor, selection);
      }, 100);
    }
    
    return () => timer && clearTimeout(timer)
  }, [editor]);

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the
    // `beforeinput` for "insertFromComposition". It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
    
  }, []);
  
  
  return {
    editor,
    value,
    onChange,
    onKeyDownCapture,
    onDOMBeforeInput,
  }
}