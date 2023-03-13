import React from 'react';
import TextBlock from '../TextBlock';
import { TreeNodeInterface } from '$app/interfaces/index';

const fontSize: Record<string, string> = {
  1: 'mt-8 text-3xl',
  2: 'mt-6 text-2xl',
  3: 'mt-4 text-xl',
};
export default function HeadingBlock({ node }: { node: TreeNodeInterface }) {
  return (
    <div className={`${fontSize[node.data.level]} font-semibold	`}>
      <TextBlock
        node={{
          ...node,
          children: [],
        }}
      />
    </div>
  );
}
