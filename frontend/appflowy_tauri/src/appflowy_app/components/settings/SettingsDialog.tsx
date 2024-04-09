/**
 * @figmaUrl https://www.figma.com/file/MF5CWlOzBRuGHp45zAXyUH/Appflowy%3A-Desktop-Settings?type=design&node-id=100%3A2119&mode=design&t=4Wb0Zg5NOFO36kOf-1
 */

import Dialog, { DialogProps } from '@mui/material/Dialog';
import { Settings } from '$app/components/settings/Settings';
import { useCallback, useEffect, useRef, useState } from 'react';
import DialogTitle from '@mui/material/DialogTitle';
import { IconButton } from '@mui/material';
import { ReactComponent as CloseIcon } from '$app/assets/close.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as UpIcon } from '$app/assets/up.svg';
import { SettingsRoutes } from '$app/components/settings/workplace/const';
import DialogContent from '@mui/material/DialogContent';
import { Login } from '$app/components/settings/Login';
import SwipeableViews from 'react-swipeable-views';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { currentUserActions, LoginState } from '$app_reducers/current-user/slice';

export const SettingsDialog = (props: DialogProps) => {
  const dispatch = useAppDispatch();
  const [routes, setRoutes] = useState<SettingsRoutes[]>([]);
  const loginState = useAppSelector((state) => state.currentUser.loginState);
  const lastLoginStateRef = useRef(loginState);
  const { t } = useTranslation();
  const handleForward = useCallback((route: SettingsRoutes) => {
    setRoutes((prev) => {
      return [...prev, route];
    });
  }, []);

  const handleBack = useCallback(() => {
    setRoutes((prevState) => {
      return prevState.slice(0, -1);
    });
    dispatch(currentUserActions.resetLoginState());
  }, [dispatch]);

  const handleClose = useCallback(() => {
    dispatch(currentUserActions.resetLoginState());
    props?.onClose?.({}, 'backdropClick');
  }, [dispatch, props]);

  const currentRoute = routes[routes.length - 1];

  useEffect(() => {
    if (lastLoginStateRef.current === LoginState.Loading && loginState === LoginState.Success) {
      handleClose();
      return;
    }

    lastLoginStateRef.current = loginState;
  }, [loginState, handleClose]);

  return (
    <Dialog
      {...props}
      PaperProps={{
        style:
          currentRoute === SettingsRoutes.LOGIN
            ? {
                width: '600px',
                height: '461px',
              }
            : {
                width: '90%',
                maxWidth: '729px',
                height: '85%',
              },
      }}
      onKeyDown={(e) => {
        if (e.key === 'Escape') {
          e.preventDefault();
        }
      }}
      scroll={'paper'}
    >
      <SwipeableViews
        slideStyle={{
          overflow: 'hidden',
        }}
        className={'h-full overflow-hidden'}
        axis={'x'}
        index={routes.length === 0 ? 0 : 1}
      >
        <div className={'flex h-full w-full flex-col'} dir={'ltr'} hidden={routes.length > 0}>
          {routes.length === 0 && <Settings onForward={handleForward} />}
        </div>
        <div className={'relative flex h-full w-full flex-col'} dir={'ltr'} hidden={routes.length === 0}>
          {routes.length > 0 && (
            <>
              <DialogTitle className={'flex items-center gap-2'}>
                <UpIcon className={'h-8 w-8 -rotate-90 transform cursor-pointer'} onClick={handleBack} />
                {t('button.back')}
              </DialogTitle>
              <IconButton onClick={handleClose} className={'absolute right-2 top-2'}>
                <CloseIcon className={'h-8 w-8'} />
              </IconButton>
              <DialogContent>
                {currentRoute === SettingsRoutes.LOGIN ? <Login onBack={handleBack} /> : null}
              </DialogContent>
            </>
          )}
        </div>
      </SwipeableViews>
    </Dialog>
  );
};
