import React from 'react';
import { Block } from '$app/interfaces';

export default function PageBlock({ block }: { block: Block }) {
  return <div className='cursor-pointer underline'>{block.data.title}</div>;
}
