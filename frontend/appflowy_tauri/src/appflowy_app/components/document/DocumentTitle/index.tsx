import React, { useState } from 'react';
import { useDocumentTitle } from './DocumentTitle.hooks';
import TextBlock from '../TextBlock';
import { useTranslation } from 'react-i18next';
import DocumentBanner from '$app/components/document/DocumentBanner';
import { ContainerType, useContainerType } from '$app/hooks/document.hooks';

export default function DocumentTitle({ id }: { id: string }) {
  const { node } = useDocumentTitle(id);
  const { t } = useTranslation();
  const [hover, setHover] = useState(false);

  const containerType = useContainerType();

  if (!node || containerType !== ContainerType.DocumentPage) return null;

  return (
    <div className={'flex flex-col'} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
      <DocumentBanner id={node.id} hover={hover} />
      <div data-block-id={node.id} className='doc-title relative text-4xl font-bold'>
        <TextBlock placeholder={t('document.title.placeholder')} childIds={[]} node={node} />
      </div>
    </div>
  );
}
