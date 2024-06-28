import { usePublishContext } from '@/application/publish';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import { ReactComponent as SideOutlined } from '@/assets/side_outlined.svg';
import Outline from '@/components/publish/outline/Outline';
import { createHotKeyLabel, HOT_KEY_NAME } from '@/utils/hotkeys';
import { Drawer, IconButton, Tooltip } from '@mui/material';
import { useTranslation } from 'react-i18next';

function OutlineDrawer({ open, width, onClose }: { open: boolean; width: number; onClose: () => void }) {
  const { t } = useTranslation();
  const viewMeta = usePublishContext()?.viewMeta;

  return (
    <Drawer
      sx={{
        width,
        flexShrink: 0,
        boxShadow: 'var(--shadow)',
        '& .MuiDrawer-paper': {
          width,
          boxSizing: 'border-box',
          borderColor: 'var(--line-divider)',
          boxShadow: 'none',
        },
      }}
      variant='persistent'
      anchor='left'
      open={open}
      tabIndex={0}
      autoFocus
    >
      <div className={'flex h-full flex-col'}>
        <div className={'flex h-[64px] items-center justify-between p-4'}>
          <div
            className={'flex cursor-pointer items-center text-text-title'}
            onClick={() => {
              window.open('https://appflowy.io', '_blank');
            }}
          >
            <Logo className={'h-5 w-5'} />
            <AppflowyLogo className={'w-24'} />
          </div>
          <Tooltip
            title={
              <div className={'flex flex-col'}>
                <span>{t('sideBar.closeSidebar')}</span>
                <span className={'text-xs text-text-caption'}>{createHotKeyLabel(HOT_KEY_NAME.TOGGLE_SIDEBAR)}</span>
              </div>
            }
          >
            <IconButton onClick={onClose}>
              <SideOutlined className={'h-4 w-4 rotate-180 transform'} />
            </IconButton>
          </Tooltip>
        </div>
        <div className={'flex flex-1 flex-col overflow-y-auto px-4 pb-4'}>
          <Outline viewMeta={viewMeta} />
        </div>
      </div>
    </Drawer>
  );
}

export default OutlineDrawer;
