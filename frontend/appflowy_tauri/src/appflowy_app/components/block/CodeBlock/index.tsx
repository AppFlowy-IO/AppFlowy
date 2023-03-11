import React from 'react';
import { TreeNodeImp } from '$app/interfaces';

export default function CodeBlock({ node }: { node: TreeNodeImp }) {
  return <div>{node.data.text}</div>;
}
