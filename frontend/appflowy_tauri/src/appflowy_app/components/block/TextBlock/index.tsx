import React, { useContext, useMemo, useState } from 'react';
import { Block, BlockType } from '$app/interfaces';
import BlockComponent from '../BlockList/BlockComponent';

import { createEditor } from 'slate';
import { Slate, Editable, withReact } from 'slate-react';
import Leaf from './Leaf';
import HoveringToolbar from '$app/components/HoveringToolbar';
import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';
import { updateBlockPositionCache } from '../../../utils/tree';
import { BlockContext } from '../../../utils/block_context';
import { debounce } from '@/appflowy_app/utils/tool';

const INPUT_CHANGE_CACHE_DELAY = 300;

export default function TextBlock({ block }: { block: Block<BlockType.TextBlock> }) {
  const [editor] = useState(() => withReact(createEditor()));

  const { id } = useContext(BlockContext);

  const debounceUpdateBlockCache = useMemo(
    () => debounce(updateBlockPositionCache, INPUT_CHANGE_CACHE_DELAY),
    [id, block.id]
  );

  return (
    <div className='mb-2'>
      <Slate
        editor={editor}
        onChange={(e) => {
          if (editor.operations[0].type !== 'set_selection') {
            console.log('=== text op ===', e, editor.operations);
            // Temporary code, in the future, it is necessary to monitor the OP changes of the document to determine whether the location cache of the block needs to be updated
            debounceUpdateBlockCache(id, block.id);
          }
        }}
        value={[
          {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            type: 'paragraph',
            children: block.data.content,
          },
        ]}
      >
        <HoveringToolbar blockId={block.id} />
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
          renderLeaf={(props) => <Leaf {...props} />}
          placeholder='Enter some text...'
        />
      </Slate>
      {block.children && block.children.length > 0 ? (
        <div className='pl-[1.5em]'>
          {block.children.map((item: Block) => (
            <BlockComponent key={item.id} block={item} />
          ))}
        </div>
      ) : null}
    </div>
  );
}
