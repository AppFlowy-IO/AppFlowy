import React, { useMemo } from 'react';
import TextBlock from '../TextBlock';
import NumberedListBlock from './NumberedListBlock';
import BulletedListBlock from './BulletedListBlock';
import ColumnListBlock from './ColumnListBlock';
import { TreeNodeInterface } from '$app/interfaces/index';

export default function ListBlock({ node }: { node: TreeNodeInterface }) {
  const title = useMemo(() => {
    if (node.data.type === 'column') return <></>;
    return (
      <div className='flex-1'>
        <TextBlock
          node={{
            ...node,
            children: [],
          }}
        />
      </div>
    );
  }, [node]);

  if (node.data.type === 'numbered') {
    return <NumberedListBlock title={title} node={node} />;
  }

  if (node.data.type === 'bulleted') {
    return <BulletedListBlock title={title} node={node} />;
  }

  if (node.data.type === 'column') {
    return <ColumnListBlock node={node} />;
  }

  return null;
}
