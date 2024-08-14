import { YDoc } from '@/application/collab.type';
import { PublishProvider } from '@/application/publish';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { AFScroller } from '@/components/_shared/scroller';
import { AFConfigContext } from '@/components/app/app.hooks';
import { GlobalCommentProvider } from '@/components/global-comment';
import CollabView from '@/components/publish/CollabView';
import { OutlineDrawer } from '@/components/publish/outline';
import React, { Suspense, useCallback, useContext, useEffect, useState } from 'react';
import { PublishViewHeader } from '@/components/publish/header';
import NotFound from '@/components/error/NotFound';
import { useSearchParams } from 'react-router-dom';

export interface PublishViewProps {
  namespace: string;
  publishName: string;
}

const drawerWidth = 268;

export function PublishView ({ namespace, publishName }: PublishViewProps) {
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

  const [open, setOpen] = useState(false);

  const [search] = useSearchParams();

  const isTemplate = search.get('template') === 'true';
  const isTemplateThumb = isTemplate && search.get('thumbnail') === 'true';

  if (notFound && !doc) {
    return <NotFound />;
  }

  return (
    <PublishProvider isTemplateThumb={isTemplateThumb} namespace={namespace} publishName={publishName}>
      <div className={'h-screen w-screen'} style={{
        pointerEvents: isTemplateThumb ? 'none' : 'auto',
      }}
      >
        <AFScroller
          overflowXHidden
          style={{
            transform: open ? `translateX(${drawerWidth}px)` : 'none',
            width: open ? `calc(100% - ${drawerWidth}px)` : '100%',
            transition: 'width 0.2s ease-in-out, transform 0.2s ease-in-out',
          }}
          className={'appflowy-layout appflowy-scroll-container'}
        >
          {!isTemplate && <PublishViewHeader
            onOpenDrawer={() => {
              setOpen(true);
            }}
            openDrawer={open}
          />}

          <CollabView doc={doc} />
          {doc && !isTemplate && (
            <Suspense fallback={<ComponentLoading />}>
              <GlobalCommentProvider />
            </Suspense>
          )}
        </AFScroller>
        {open && <OutlineDrawer width={drawerWidth} open={open} onClose={() => setOpen(false)} />}
      </div>
    </PublishProvider>
  );
}

export default PublishView;
