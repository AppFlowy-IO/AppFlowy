import { TreeNode } from '@/appflowy_app/block_editor/view/tree_node';
import React, { useMemo } from 'react';
import ColumnBlock from '../ColumnBlock';

export default function ColumnListBlock({ node }: { node: TreeNode }) {
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
