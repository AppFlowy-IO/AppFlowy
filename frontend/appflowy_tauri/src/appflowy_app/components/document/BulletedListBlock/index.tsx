import React from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import { Circle } from '@mui/icons-material';
import TextBlock from '$app/components/document/TextBlock';
import NodeChildren from '$app/components/document/Node/NodeChildren';

function BulletedListBlock({ node, childIds }: { node: NestedBlock<BlockType.BulletedListBlock>; childIds?: string[] }) {
  return (
    <>
      <div className={'flex'}>
        <div className={`relative flex h-[calc(1.5em_+_2px)] min-w-[1.5em] select-none items-center px-1`}>
          <Circle sx={{ width: 8, height: 8 }} />
        </div>
        <div className={'flex-1'}>
          <TextBlock node={node} />
        </div>
      </div>
      <NodeChildren className='pl-[1.5em]' childIds={childIds} />
    </>
  );
}

export default BulletedListBlock;
