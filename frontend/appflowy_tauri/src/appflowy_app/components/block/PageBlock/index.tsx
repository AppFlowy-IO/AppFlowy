import React from 'react';
import { Block, BlockType } from '$app/interfaces';

export default function PageBlock({ block }: { block: Block<BlockType.PageBlock> }) {
  return <div className='cursor-pointer underline'>{block.data.title}</div>;
}
