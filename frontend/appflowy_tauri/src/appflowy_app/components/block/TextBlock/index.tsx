import React, { useState } from 'react';
import { Block } from '$app/interfaces';
import BlockComponent from '../BlockList/BlockComponent';

import { createEditor } from 'slate';
import { Slate, Editable, withReact } from 'slate-react';
import Leaf from './Leaf';
import HoveringToolbar from '$app/components/HoveringToolbar';
import { triggerHotkey } from '$app/utils/editor/hotkey';

export default function TextBlock({ block }: { block: Block }) {
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
            children: [{ text: block.data.text }],
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
      <div className='pl-[1.5em]'>
        {block.children?.map((item: Block) => (
          <BlockComponent key={item.id} block={item} />
        ))}
      </div>
    </div>
  );
}
