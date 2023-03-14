import { TreeNode } from '@/appflowy_app/block_editor/tree_node';
import React from 'react';

export default function CodeBlock({ node }: { node: TreeNode }) {
  return <div>{node.data.text}</div>;
}
