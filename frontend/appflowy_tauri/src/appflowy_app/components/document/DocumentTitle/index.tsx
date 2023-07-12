import React from 'react';
import { useDocumentTitle } from './DocumentTitle.hooks';
import TextBlock from '../TextBlock';
import { useTranslation } from 'react-i18next';

export default function DocumentTitle({ id }: { id: string }) {
  const { node } = useDocumentTitle(id);
  const { t } = useTranslation();

  if (!node) return null;
  return (
    <div data-block-id={node.id} className='doc-title relative mb-2 pt-[50px] text-4xl font-bold'>
      <TextBlock placeholder={t('document.title.placeholder')} childIds={[]} node={node} />
    </div>
  );
}
