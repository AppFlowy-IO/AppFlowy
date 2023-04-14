import React, { useMemo } from 'react';
import TextBlock from '../TextBlock';
import NumberedListBlock from './NumberedListBlock';
import BulletedListBlock from './BulletedListBlock';
import ColumnListBlock from './ColumnListBlock';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import { TextDelta } from '@/appflowy_app/interfaces/document';

export default function ListBlock({ node, delta }: { node: Node; delta: TextDelta[] }) {
  const title = useMemo(() => {
    if (node.data.style?.type === 'column') return <></>;
    return (
      <div className='flex-1'>
        {/*<TextBlock delta={delta} node={node} childIds={[]} />*/}
      </div>
    );
  }, [node, delta]);

  if (node.data.style?.type === 'numbered') {
    return <NumberedListBlock title={title} node={node} />;
  }

  if (node.data.style?.type === 'bulleted') {
    return <BulletedListBlock title={title} node={node} />;
  }

  if (node.data.style?.type === 'column') {
    return <ColumnListBlock node={node} />;
  }

  return null;
}
