import React, { useState } from 'react';
import { Block, BlockType } from '$app/interfaces';
import BlockComponent from '../BlockList/BlockComponent';

import { createEditor } from 'slate';
import { Slate, Editable, withReact } from 'slate-react';
import Leaf from './Leaf';
import HoveringToolbar from '$app/components/HoveringToolbar';
import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';

export default function TextBlock({ block }: { block: Block<BlockType.TextBlock> }) {
  const [editor] = useState(() => withReact(createEditor()));

  return (
    <div className='mb-2'>
      <Slate
        editor={editor}
        onChange={(e) => console.log('===', e, editor.operations)}
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
