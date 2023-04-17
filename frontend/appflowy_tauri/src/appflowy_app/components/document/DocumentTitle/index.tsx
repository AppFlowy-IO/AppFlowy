import React from 'react';
import { useDocumentTitle } from './DocumentTitle.hooks';
import TextBlock from '../TextBlock';
import { NodeContext } from '../_shared/SubscribeNode.hooks';

export default function DocumentTitle({ id }: { id: string }) {
  const { node } = useDocumentTitle(id);
  if (!node) return null;
  return (
    <NodeContext.Provider value={node}>
      <div data-block-id={node.id} className='doc-title relative pt-[50px] text-4xl font-bold'>
        <TextBlock placeholder='Untitled' childIds={[]} node={node} />
      </div>
    </NodeContext.Provider>
  );
}
