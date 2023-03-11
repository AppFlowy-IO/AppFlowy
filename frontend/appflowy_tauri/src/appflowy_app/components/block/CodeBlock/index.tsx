import React from 'react';
import { TreeNodeInterface } from '$app/interfaces';

export default function CodeBlock({ node }: { node: TreeNodeInterface }) {
  return <div>{node.data.text}</div>;
}
