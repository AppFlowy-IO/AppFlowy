import { TreeNode } from '@/appflowy_app/block_editor/tree_node';
import React from 'react';

export default function PageBlock({ node }: { node: TreeNode }) {
  return <div className='cursor-pointer underline'>{node.data.title}</div>;
}
