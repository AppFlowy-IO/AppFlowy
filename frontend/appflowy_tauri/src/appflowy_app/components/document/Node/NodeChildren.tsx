import React from 'react';
import NodeComponent from '$app/components/document/Node/index';

function NodeChildren({ childIds, ...props }: { childIds?: string[] } & React.HTMLAttributes<HTMLDivElement>) {
  return childIds && childIds.length > 0 ? (
    <div {...props}>
      {childIds.map((item) => (
        <NodeComponent key={item} id={item} />
      ))}
    </div>
  ) : null;
}

export default React.memo(NodeChildren);
