import { HEADER_HEIGHT } from '@/application/constants';
import { UIVariant } from '@/application/types';
import { Breadcrumb } from '@/components/_shared/breadcrumb';
import { withAppBreadcrumb } from '@/components/_shared/breadcrumb/withAppBreadcrumb';
import { withPublishBreadcrumb } from '@/components/_shared/breadcrumb/withPublishBreadcrumb';
import { MobileDrawer } from '@/components/_shared/mobile-drawer';
import MobileFolder from '@/components/_shared/mobile-topbar/MobileFolder';
import PublishMobileFolder from '@/components/_shared/mobile-topbar/PublishMobileFolder';
import MoreActionsContent from '@/components/_shared/more-actions/MoreActionsContent';
import { openOrDownload } from '@/utils/open_schema';
import { IconButton } from '@mui/material';
import React, { useCallback } from 'react';
import { ReactComponent as MenuIcon } from '@/assets/side_outlined.svg';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';

const PublishBreadcrumb = withPublishBreadcrumb(Breadcrumb);
const AppBreadcrumb = withAppBreadcrumb(Breadcrumb);

function MobileTopBar ({ variant }: { variant?: UIVariant }) {
  const [openFolder, setOpenFolder] = React.useState(false);
  const [openMore, setOpenMore] = React.useState(false);

  const handleOpenFolder = useCallback(() => {
    setOpenFolder(true);
  }, []);

  const handleCloseFolder = useCallback(() => {
    setOpenFolder(false);
  }, []);

  const handleOpenMore = useCallback(() => {
    setOpenMore(true);
  }, []);
  const handleCloseMore = useCallback(() => {
    setOpenMore(false);
  }, []);

  return (
    <div
      style={{
        backdropFilter: 'saturate(180%) blur(16px)',
        background: 'var(--bg-header)',
        height: HEADER_HEIGHT,
        minHeight: HEADER_HEIGHT,
      }}
      className={'flex appflowy-top-bar transform-gpu sticky top-0 z-10 items-center justify-between w-full h-[48px] min-h-[48px] px-4 gap-2'}
    >
      <MobileDrawer
        swipeAreaWidth={window.innerWidth - 56}
        onOpen={handleOpenFolder}
        onClose={handleCloseFolder}
        open={openFolder}
        anchor={'left'}
        showPuller={false}
        triggerNode={<IconButton><MenuIcon /></IconButton>}
      >
        {variant === UIVariant.App ? <MobileFolder onClose={handleCloseFolder} /> :
          <PublishMobileFolder onClose={handleCloseFolder} />}

      </MobileDrawer>

      {variant === UIVariant.Publish ? <PublishBreadcrumb /> : <AppBreadcrumb />}
      <div className={'flex items-center gap-4'}>
        <button
          onClick={() => openOrDownload()}
        >
          <Logo className={'h-6 w-6'} />
        </button>
        <MobileDrawer
          onOpen={handleOpenMore}
          onClose={handleCloseMore}
          open={openMore}
          anchor={'bottom'}
          triggerNode={<IconButton className={'opacity-70'}><MoreIcon /></IconButton>}
        >
          <div className={'h-full w-full pt-10 px-2'}>
            <MoreActionsContent itemClicked={handleCloseMore} />

          </div>
        </MobileDrawer>
      </div>
    </div>
  );
}

export default MobileTopBar;