import { Popover } from '@/components/_shared/popover';
import { ThemeModeContext } from '@/components/app/useAppThemeMode';
import { openUrl } from '@/utils/url';
import { IconButton } from '@mui/material';
import React, { useContext, useMemo } from 'react';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { ReactComponent as MoonIcon } from '@/assets/moon.svg';
import { ReactComponent as SunIcon } from '@/assets/sun.svg';
import { ReactComponent as ReportIcon } from '@/assets/report.svg';
import { useTranslation } from 'react-i18next';

function MoreActions() {
  const { isDark, setDark } = useContext(ThemeModeContext) || {};
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const open = Boolean(anchorEl);

  const { t } = useTranslation();

  const actions = useMemo(() => {
    return [
      isDark
        ? {
            Icon: SunIcon,
            label: t('settings.appearance.themeMode.light'),
            onClick: () => {
              setDark?.(false);
            },
          }
        : {
            Icon: MoonIcon,
            label: t('settings.appearance.themeMode.dark'),
            onClick: () => {
              setDark?.(true);
            },
          },
      {
        Icon: ReportIcon,
        label: t('publish.reportPage'),
        onClick: () => {
          void openUrl('', '_blank');
        },
      },
    ];
  }, [isDark, t, setDark]);

  return (
    <>
      <IconButton onClick={handleClick}>
        <MoreIcon className={'text-text-caption'} />
      </IconButton>
      <Popover
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        open={open}
        anchorEl={anchorEl}
        onClose={handleClose}
      >
        <div className={'flex w-[240px] flex-col gap-2 px-2 py-2'}>
          {actions.map((action, index) => (
            <button
              onClick={action.onClick}
              key={index}
              className={
                'flex items-center gap-2 rounded-[8px] p-1.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
              }
            >
              <action.Icon />
              <span>{action.label}</span>
            </button>
          ))}
        </div>
      </Popover>
    </>
  );
}

export default MoreActions;
