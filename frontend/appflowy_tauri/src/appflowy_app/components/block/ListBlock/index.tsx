import React, { useMemo } from 'react';
import { Block, BlockType } from '$app/interfaces';
import TextBlock from '../TextBlock';
import NumberedListBlock from './NumberedListBlock';
import BulletedListBlock from './BulletedListBlock';
import ColumnListBlock from './ColumnListBlock';

export default function ListBlock({ block }: { block: Block<BlockType.ListBlock> }) {
  const title = useMemo(() => {
    if (block.data.type === 'column') return <></>;
    return (
      <div className='flex-1'>
        <TextBlock
          block={{
            ...block,
            children: [],
          }}
        />
      </div>
    );
  }, [block]);

  if (block.data.type === 'numbered') {
    return <NumberedListBlock title={title} block={block} />;
  }

  if (block.data.type === 'bulleted') {
    return <BulletedListBlock title={title} block={block} />;
  }

  if (block.data.type === 'column') {
    return <ColumnListBlock block={block} />;
  }

  return null;
}
