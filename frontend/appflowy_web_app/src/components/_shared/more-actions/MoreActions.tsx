import { invalidToken } from '@/application/session/token';
import CacheClearingDialog from '@/components/_shared/modal/CacheClearingDialog';
import Import from '@/components/_shared/more-actions/importer/Import';
import { Popover } from '@/components/_shared/popover';
import { AFConfigContext } from '@/components/main/app.hooks';
import { ThemeModeContext } from '@/components/main/useAppThemeMode';
import { openUrl } from '@/utils/url';
import { IconButton } from '@mui/material';
import React, { useCallback, useContext, useMemo } from 'react';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { ReactComponent as MoonIcon } from '@/assets/moon.svg';
import { ReactComponent as SunIcon } from '@/assets/sun.svg';
import { ReactComponent as LoginIcon } from '@/assets/login.svg';
import { ReactComponent as ReportIcon } from '@/assets/report.svg';
import { ReactComponent as TrashIcon } from '@/assets/trash.svg';
import { ReactComponent as ImportIcon } from '@/assets/import.svg';
import { useTranslation } from 'react-i18next';
import { useNavigate, useSearchParams } from 'react-router-dom';

function MoreActions () {
  const { isDark, setDark } = useContext(ThemeModeContext) || {};
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const [openConfirm, setOpenConfirm] = React.useState(false);

  const handleClose = () => {
    setAnchorEl(null);
  };

  const open = Boolean(anchorEl);

  const { t } = useTranslation();

  const navigate = useNavigate();

  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated || false;
  const [, setSearch] = useSearchParams();

  const handleLogin = useCallback(() => {
    invalidToken();
    navigate('/login?redirectTo=' + encodeURIComponent(window.location.href));
  }, [navigate]);
  const actions = useMemo(() => {
    const items = [

      {
        Icon: LoginIcon,
        label: isAuthenticated ? t('button.logout') : t('web.login'),
        onClick: handleLogin,
      },

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
          void openUrl('https://report.appflowy.io/', '_blank');
        },
      },
      {
        Icon: TrashIcon,
        label: t('settings.files.clearCache'),
        onClick: () => {
          setOpenConfirm(true);
        },
      },
    ];

    const importShow = false;
    
    if (importShow) {
      items.unshift({
        Icon: ImportIcon,
        label: t('web.import'),
        onClick: () => {
          setSearch(prev => {
            prev.set('action', 'import');
            prev.set('source', 'notion');
            return prev;
          });
        },
      });
    }

    return items;
  }, [t, isAuthenticated, handleLogin, isDark, setSearch, setDark]);

  return (
    <>
      <IconButton onClick={handleClick}>
        <MoreIcon className={'text-text-caption'} />
      </IconButton>
      {open && (
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
                onClick={() => {
                  action.onClick();
                  handleClose();
                }}
                key={index}
                className={
                  'flex items-center gap-2 rounded-[8px] p-1.5 text-sm hover:bg-content-blue-50 focus:bg-content-blue-50 focus:outline-none'
                }
              >
                <action.Icon className={'w-4 h-4'} />
                <span>{action.label}</span>
              </button>
            ))}

          </div>
        </Popover>
      )}
      <CacheClearingDialog
        open={openConfirm}
        onClose={() => setOpenConfirm(false)}
      />
      <Import />
    </>
  );
}

export default MoreActions;
