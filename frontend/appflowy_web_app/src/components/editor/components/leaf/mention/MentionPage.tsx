import { useNavigateToView } from '@/application/folder-yjs';
import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import React from 'react';

function MentionPage({ pageId }: { pageId: string }) {
  const onNavigateToView = useNavigateToView();
  const { icon, name } = usePageInfo(pageId);

  return (
    <span
      onClick={() => {
        onNavigateToView?.(pageId);
      }}
      className={`mention-inline px-1 underline`}
      contentEditable={false}
    >
      <span className={'mention-icon'}>{icon}</span>

      <span className={'mention-content'}>{name}</span>
    </span>
  );
}

export default MentionPage;
