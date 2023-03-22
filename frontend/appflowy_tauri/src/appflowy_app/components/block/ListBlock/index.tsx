import React, { useMemo } from 'react';
import TextBlock from '../TextBlock';
import NumberedListBlock from './NumberedListBlock';
import BulletedListBlock from './BulletedListBlock';
import ColumnListBlock from './ColumnListBlock';
import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import { BlockCommonProps } from '@/appflowy_app/interfaces';

export default function ListBlock({ node, version }: BlockCommonProps<TreeNode>) {
  const title = useMemo(() => {
    if (node.data.type === 'column') return <></>;
    return (
      <div className='flex-1'>
        <TextBlock version={version} node={node} needRenderChildren={false} />
      </div>
    );
  }, [node, version]);

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
