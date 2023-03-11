import React from 'react';
import { TreeNodeImp } from '$app/interfaces';

export default function PageBlock({ node }: { node: TreeNodeImp }) {
  return <div className='cursor-pointer underline'>{node.data.title}</div>;
}
