import { layoutMap, ViewLayout, YjsFolderKey } from '@/application/collab.type';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import React from 'react';
import { useNavigate } from 'react-router-dom';

function MentionPage({ pageId }: { pageId: string }) {
  const navigate = useNavigate();
  const { workspaceId } = useId();
  const { view, icon, name } = usePageInfo(pageId);

  return (
    <span
      onClick={() => {
        const layout = parseInt(view?.get(YjsFolderKey.layout) ?? '0') as ViewLayout;

        navigate(`/workspace/${workspaceId}/${layoutMap[layout]}/${pageId}`);
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
