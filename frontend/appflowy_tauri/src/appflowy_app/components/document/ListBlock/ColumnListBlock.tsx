import React, { useMemo } from 'react';
import ColumnBlock from '../ColumnBlock';

import { Node } from '$app/interfaces/document';

export default function ColumnListBlock({
  node,
  childIds,
}: {
  node: Node & {
    data: Record<string, any>;
  };
  childIds?: string[];
}) {
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
            width={`calc((100% - ${resizerWidth}px) * ${node.data.ratio})`}
            id={item}
          />
        ))}
      </div>
    </>
  );
}
