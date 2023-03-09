import { Block, BlockType } from '@/appflowy_app/interfaces';
import React from 'react';
import BlockComponent from '../BlockList/BlockComponent';

export default function NumberedListBlock({ title, block }: { title: JSX.Element; block: Block<BlockType.ListBlock> }) {
  return (
    <div className='numbered-list-block'>
      {title}
      <div>
        {block.children?.map((item) => (
          <div key={item.id}>
            <BlockComponent block={item} />
          </div>
        ))}
      </div>
    </div>
  );
}
