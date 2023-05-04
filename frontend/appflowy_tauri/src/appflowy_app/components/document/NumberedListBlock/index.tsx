import React from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import TextBlock from '$app/components/document/TextBlock';
import NodeChildren from '$app/components/document/Node/NodeChildren';
import { useNumberedListBlock } from '$app/components/document/NumberedListBlock/NumberedListBlock.hooks';

function NumberedListBlock({ node, childIds }: { node: NestedBlock<BlockType.NumberedListBlock>; childIds?: string[] }) {
  const { index } = useNumberedListBlock(node);

  return (
    <>
      <div className={'flex'}>
        <div
          className={`relative flex h-[calc(1.5em_+_4px)] min-w-[1.5em] select-none  items-center whitespace-nowrap px-1 text-left`}
        >
          {index}.
        </div>
        <div className={'flex-1'}>
          <TextBlock node={node} />
        </div>
      </div>
      <NodeChildren className='pl-[1.5em]' childIds={childIds} />
    </>
  );
}

export default NumberedListBlock;
