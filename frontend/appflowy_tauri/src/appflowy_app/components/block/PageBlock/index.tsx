import React from 'react';
import { TreeNodeInterface } from '$app/interfaces';

export default function PageBlock({ node }: { node: TreeNodeInterface }) {
  return <div className='cursor-pointer underline'>{node.data.title}</div>;
}
