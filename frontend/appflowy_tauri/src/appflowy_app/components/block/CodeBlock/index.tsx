import React from 'react';
import { Block, BlockType } from '$app/interfaces';

export default function CodeBlock({ block }: { block: Block<BlockType.CodeBlock> }) {
  return <div>{block.data.text}</div>;
}
