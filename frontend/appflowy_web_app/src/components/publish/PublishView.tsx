import { YDoc } from '@/application/types';
import { PublishProvider } from '@/application/publish';
import { useOutlineDrawer } from '@/components/_shared/outline/outline.hooks';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { AFScroller } from '@/components/_shared/scroller';
import { AFConfigContext } from '@/components/main/app.hooks';
import { GlobalCommentProvider } from '@/components/global-comment';
import CollabView from '@/components/publish/CollabView';
import SideBar from '@/components/publish/SideBar';
import React, { Suspense, useCallback, useContext, useEffect, useState } from 'react';
import { PublishViewHeader } from '@/components/publish/header';
import NotFound from '@/components/error/NotFound';
import { useSearchParams } from 'react-router-dom';

export interface PublishViewProps {
  namespace: string;
  publishName: string;
}

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

  const [search] = useSearchParams();

  const isTemplate = search.get('template') === 'true';
  const isTemplateThumb = isTemplate && search.get('thumbnail') === 'true';

  useEffect(() => {
    if (!isTemplateThumb) return;
    document.documentElement.setAttribute('thumbnail', 'true');
  }, [isTemplateThumb]);

  const {
    drawerOpened,
    drawerWidth,
    setDrawerWidth,
    toggleOpenDrawer,
  } = useOutlineDrawer();

  if (notFound && !doc) {
    return <NotFound />;
  }

  return (
    <PublishProvider
      isTemplateThumb={isTemplateThumb} isTemplate={isTemplate} namespace={namespace}
      publishName={publishName}
    >
      <div
        className={'h-screen w-screen'} style={isTemplateThumb ? {
        pointerEvents: 'none',
        transform: 'scale(0.333)',
        transformOrigin: '0 0',
        width: '300vw',
        height: '400vh',
        overflow: 'hidden',
      } : undefined}
      >
        <AFScroller
          overflowXHidden
          overflowYHidden={isTemplateThumb}
          style={{
            transform: drawerOpened ? `translateX(${drawerWidth}px)` : 'none',
            width: drawerOpened ? `calc(100% - ${drawerWidth}px)` : '100%',
            transition: 'width 0.2s ease-in-out, transform 0.2s ease-in-out',
          }}
          className={'appflowy-layout appflowy-scroll-container h-full'}
        >
          {!isTemplate && <PublishViewHeader
            onOpenDrawer={() => {
              toggleOpenDrawer(true);
            }}
            drawerWidth={drawerWidth}
            onCloseDrawer={() => {
              toggleOpenDrawer(false);
            }}
            openDrawer={drawerOpened}
          />}

          <CollabView doc={doc} />
          {doc && !isTemplate && (
            <Suspense fallback={<ComponentLoading />}>
              <GlobalCommentProvider />
            </Suspense>
          )}

        </AFScroller>
        {drawerOpened &&
          <SideBar
            onResizeDrawerWidth={setDrawerWidth} drawerWidth={drawerWidth} drawerOpened={drawerOpened}
            toggleOpenDrawer={toggleOpenDrawer}
          />
        }
      </div>
    </PublishProvider>
  );
}

export default PublishView;
