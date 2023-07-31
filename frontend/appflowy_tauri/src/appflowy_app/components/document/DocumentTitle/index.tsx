import React, { useState } from 'react';
import { useDocumentTitle } from './DocumentTitle.hooks';
import TextBlock from '../TextBlock';
import { useTranslation } from 'react-i18next';
import TitleButtonGroup from './TitleButtonGroup';
import DocumentTopPanel from './DocumentTopPanel';

export default function DocumentTitle({ id }: { id: string }) {
  const { node, onUpdateCover, onUpdateIcon } = useDocumentTitle(id);
  const { t } = useTranslation();
  const [hover, setHover] = useState(false);

  if (!node) return null;

  return (
    <div className={'flex flex-col'} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
      <DocumentTopPanel onUpdateCover={onUpdateCover} onUpdateIcon={onUpdateIcon} node={node} />
      <div
        style={{
          opacity: hover ? 1 : 0,
        }}
      >
        <TitleButtonGroup node={node} onUpdateCover={onUpdateCover} onUpdateIcon={onUpdateIcon} />
      </div>
      <div data-block-id={node.id} className='doc-title relative text-4xl font-bold'>
        <TextBlock placeholder={t('document.title.placeholder')} childIds={[]} node={node} />
      </div>
    </div>
  );
}
