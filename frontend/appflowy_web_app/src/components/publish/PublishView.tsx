import { YDoc } from '@/application/collab.type';
import { PublishProvider } from '@/application/publish';
import { AFScroller } from '@/components/_shared/scroller';
import { AFConfigContext } from '@/components/app/AppConfig';
import CollabView from '@/components/publish/CollabView';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import { PublishViewHeader } from 'src/components/publish/header';
import NotFound from '@/components/error/NotFound';

export interface PublishViewProps {
  namespace: string;
  publishName: string;
}

export function PublishView({ namespace, publishName }: PublishViewProps) {
  const [doc, setDoc] = useState<YDoc | undefined>();
  const [notFound, setNotFound] = useState<boolean>(false);
  const service = useContext(AFConfigContext)?.service;
  const openPublishView = useCallback(async () => {
    let doc;

    setNotFound(false);
    setDoc(undefined);
    try {
      doc = await service?.getPublishView(namespace, publishName);
    } catch (e) {
      setNotFound(true);
      return;
    }

    setDoc(doc);
  }, [namespace, publishName, service]);

  useEffect(() => {
    void openPublishView();
  }, [openPublishView]);

  if (notFound && !doc) {
    return <NotFound />;
  }

  return (
    <PublishProvider namespace={namespace} publishName={publishName}>
      <div className={'h-screen w-screen'}>
        <PublishViewHeader />
        <AFScroller
          overflowXHidden
          style={{
            height: 'calc(100vh - 64px)',
          }}
          className={'appflowy-layout appflowy-scroll-container'}
        >
          <CollabView doc={doc} />
        </AFScroller>
      </div>
    </PublishProvider>
  );
}

export default PublishView;
