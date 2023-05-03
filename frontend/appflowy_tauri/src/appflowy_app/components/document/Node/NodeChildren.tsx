import React from 'react';
import NodeComponent from '$app/components/document/Node/index';

function NodeChildren({ childIds }: { childIds?: string[] }) {
  return childIds && childIds.length > 0 ? (
    <div className='pl-[1.5em]'>
      {childIds.map((item) => (
        <NodeComponent key={item} id={item} />
      ))}
    </div>
  ) : null;
}

export default NodeChildren;
