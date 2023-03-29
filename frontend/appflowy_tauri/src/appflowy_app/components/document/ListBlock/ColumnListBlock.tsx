import React, { useMemo } from 'react';
import ColumnBlock from '../ColumnBlock';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';

export default function ColumnListBlock({ node, childIds }: { node: Node; childIds?: string[] }) {
  const resizerWidth = useMemo(() => {
    return 46 * (node.children?.length || 0);
  }, [node.children?.length]);
  return (
    <>
      <div className='column-list-block flex-grow-1 flex flex-row'>
        {childIds?.map((item, index) => (
          <ColumnBlock
            key={item}
            index={index}
            width={`calc((100% - ${resizerWidth}px) * ${node.data.style?.ratio})`}
            id={item}
          />
        ))}
      </div>
    </>
  );
}
