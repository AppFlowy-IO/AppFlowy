import React, { useContext, useMemo, useState } from 'react';
import { TreeNodeInterface } from '$app/interfaces';
import BlockComponent from '../BlockList/BlockComponent';

import { createEditor } from 'slate';
import { Slate, Editable, withReact } from 'slate-react';
import Leaf from './Leaf';
import HoveringToolbar from '$app/components/HoveringToolbar';
import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';
import { BlockContext } from '$app/utils/block_context';
import { debounce } from '@/appflowy_app/utils/tool';
import { getBlockEditor } from '@/appflowy_app/block_editor/index';

const INPUT_CHANGE_CACHE_DELAY = 300;

export default function TextBlock({ node }: { node: TreeNodeInterface }) {
  const blockEditor = getBlockEditor();
  if (!blockEditor) return null;

  const [editor] = useState(() => withReact(createEditor()));

  const { id } = useContext(BlockContext);

  const debounceUpdateBlockCache = useMemo(
    () => debounce(blockEditor.renderTree.updateNodeRect, INPUT_CHANGE_CACHE_DELAY),
    [id, node.id]
  );

  return (
    <div className='mb-2'>
      <Slate
        editor={editor}
        onChange={(e) => {
          if (editor.operations[0].type !== 'set_selection') {
            console.log('=== text op ===', e, editor.operations);
            // Temporary code, in the future, it is necessary to monitor the OP changes of the document to determine whether the location cache of the block needs to be updated
            debounceUpdateBlockCache(node.id);
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
        <HoveringToolbar blockId={node.id} />
        <Editable
          onKeyDownCapture={(event) => {
            switch (event.key) {
              case 'Enter': {
                event.stopPropagation();
                event.preventDefault();
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
      {node.children && node.children.length > 0 ? (
        <div className='pl-[1.5em]'>
          {node.children.map((item) => (
            <BlockComponent key={item.id} node={item} />
          ))}
        </div>
      ) : null}
    </div>
  );
}
