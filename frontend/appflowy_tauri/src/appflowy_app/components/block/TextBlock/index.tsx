import React, { useContext, useEffect, useState } from 'react';
import BlockComponent from '../BlockList/BlockComponent';

import { Editor, Transforms, createEditor } from 'slate';
import { Slate, Editable, withReact, ReactEditor } from 'slate-react';
import Leaf from './Leaf';
import HoveringToolbar from '$app/components/HoveringToolbar';
import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';
import { BlockContext, SelectionContext } from '@/appflowy_app/utils/block';
import { TreeNode } from '@/appflowy_app/block_editor/tree_node';
import { triggerEnter } from '@/appflowy_app/utils/slate/action';

export default function TextBlock({
  node,
  needRenderChildren = true,
}: {
  node: TreeNode;
  needRenderChildren?: boolean;
}) {
  const [editor] = useState(() => withReact(createEditor()));

  const { focusNodeId } = useContext(SelectionContext);
  const { blockEditor } = useContext(BlockContext);

  useEffect(() => {
    if (focusNodeId !== node.id) {
      return;
    }
    ReactEditor.focus(editor);
    Transforms.select(editor, Editor.end(editor, []));
  }, [focusNodeId, node.id, editor]);

  return (
    <div className='py-1'>
      <Slate
        editor={editor}
        onChange={(e) => {
          if (editor.operations[0].type !== 'set_selection') {
            console.log('=== text op ===', e, editor.operations);
          }
        }}
        value={[
          {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            type: 'paragraph',
            children: node.data.content,
          },
        ]}
      >
        <HoveringToolbar node={node} blockId={node.id} />
        <Editable
          onKeyDownCapture={(event) => {
            switch (event.key) {
              case 'Enter': {
                event.stopPropagation();
                event.preventDefault();
                if (blockEditor) {
                  triggerEnter(blockEditor, node);
                }

                return;
              }
            }

            triggerHotkey(event, editor);
          }}
          onDOMBeforeInput={(e) => {
            // COMPAT: in Apple, `compositionend` is dispatched after the
            // `beforeinput` for "insertFromComposition". It will cause repeated characters when inputting Chinese.
            // Here, prevent the beforeInput event and wait for the compositionend event to take effect
            if (e.inputType === 'insertFromComposition') {
              e.preventDefault();
            }
          }}
          renderLeaf={(props) => <Leaf {...props} />}
          placeholder='Enter some text...'
        />
      </Slate>
      {needRenderChildren && node.children.length > 0 ? (
        <div className='pl-[1.5em]'>
          {node.children.map((item) => (
            <BlockComponent key={item.id} node={item} />
          ))}
        </div>
      ) : null}
    </div>
  );
}
