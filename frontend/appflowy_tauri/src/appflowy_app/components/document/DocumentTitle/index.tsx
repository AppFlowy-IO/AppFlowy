import React from 'react';
import { useDocumentTitle } from './DocumentTitle.hooks';
import TextBlock from '../TextBlock';

export default function DocumentTitle({ id }: { id: string }) {
  const { node } = useDocumentTitle(id);
  if (!node) return null;
  return (
    <div data-block-id={node.id} className='doc-title relative mb-2 pt-[50px] text-4xl font-bold'>
      <TextBlock placeholder='Untitled' childIds={[]} node={node} />
    </div>
  );
}
