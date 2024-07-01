import { YDoc } from '@/application/collab.type';
import { PublishProvider } from '@/application/publish';
import { AFScroller } from '@/components/_shared/scroller';
import { AFConfigContext } from '@/components/app/AppConfig';
import CollabView from '@/components/publish/CollabView';
import OutlineDrawer from '@/components/publish/outline/OutlineDrawer';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import { PublishViewHeader } from 'src/components/publish/header';
import NotFound from '@/components/error/NotFound';

export interface PublishViewProps {
  namespace: string;
  publishName: string;
}

const drawerWidth = 268;

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

  const [open, setOpen] = useState(false);

  const onKeyDown = useCallback((e: KeyboardEvent) => {
    switch (true) {
      case createHotkey(HOT_KEY_NAME.TOGGLE_SIDEBAR)(e):
        e.preventDefault();
        // setOpen((prev) => !prev);
        break;
      default:
        break;
    }
  }, []);

  useEffect(() => {
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [onKeyDown]);
  if (notFound && !doc) {
    return <NotFound />;
  }

  return (
    <PublishProvider namespace={namespace} publishName={publishName}>
      <div className={'h-screen w-screen'}>
        <AFScroller
          overflowXHidden
          style={{
            transform: open ? `translateX(${drawerWidth}px)` : 'none',
            width: open ? `calc(100% - ${drawerWidth}px)` : '100%',
            transition: 'width 0.2s ease-in-out, transform 0.2s ease-in-out',
          }}
          className={'appflowy-layout appflowy-scroll-container'}
        >
          <PublishViewHeader
            onOpenDrawer={() => {
              setOpen(true);
            }}
            openDrawer={open}
          />

          <CollabView doc={doc} />
        </AFScroller>
        {open && <OutlineDrawer width={drawerWidth} open={open} onClose={() => setOpen(false)} />}
      </div>
    </PublishProvider>
  );
}

export default PublishView;
