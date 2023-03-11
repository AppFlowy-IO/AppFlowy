import { TreeNodeInterface } from '@/appflowy_app/interfaces';
import React, { useMemo } from 'react';
import ColumnBlock from '../ColumnBlock/index';

export default function ColumnListBlock({ node }: { node: TreeNodeInterface }) {
  const resizerWidth = useMemo(() => {
    return 46 * (node.children?.length || 0);
  }, [node.children?.length]);
  return (
    <>
      <div className='column-list-block flex-grow-1 flex flex-row'>
        {node.children?.map((item, index) => (
          <ColumnBlock key={item.id} index={index} resizerWidth={resizerWidth} node={item} />
        ))}
      </div>
    </>
  );
}
