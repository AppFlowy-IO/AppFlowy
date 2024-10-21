import { YDoc } from '@/application/types';
import { useOutlineDrawer } from '@/components/_shared/outline/outline.hooks';
import { AFScroller } from '@/components/_shared/scroller';
import { PublishViewHeader } from '@/components/publish/header';
import PublishMain from '@/components/publish/PublishMain';
import SideBar from '@/components/publish/SideBar';
import React from 'react';

function PublishLayout ({ isTemplateThumb, isTemplate, doc }: {
  isTemplateThumb: boolean;
  isTemplate: boolean;
  doc?: YDoc;
}) {
  const {
    drawerOpened,
    drawerWidth,
    setDrawerWidth,
    toggleOpenDrawer,
  } = useOutlineDrawer();

  return (
    <div
      className={'h-screen w-screen'}
      style={isTemplateThumb ? {
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

        <PublishMain
          doc={doc}
          isTemplate={isTemplate}
        />

      </AFScroller>
      {drawerOpened &&
        <SideBar
          onResizeDrawerWidth={setDrawerWidth}
          drawerWidth={drawerWidth}
          drawerOpened={drawerOpened}
          toggleOpenDrawer={toggleOpenDrawer}
        />
      }
    </div>
  );
}

export default PublishLayout;