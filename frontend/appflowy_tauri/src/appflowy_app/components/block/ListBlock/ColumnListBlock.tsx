import { Block, BlockType } from '@/appflowy_app/interfaces';
import React, { useMemo } from 'react';
import ColumnBlock from '../ColumnBlock/index';

export default function ColumnListBlock({ block }: { block: Block<BlockType.ListBlock> }) {
  const resizerWidth = useMemo(() => {
    return 46 * (block.children?.length || 0);
  }, [block.children?.length]);
  return (
    <div className='column-list-block flex-grow-1 relative flex flex-row'>
      {block.children?.map((item, index) => (
        <ColumnBlock key={item.id} index={index} resizerWidth={resizerWidth} block={item} />
      ))}
    </div>
  );
}
