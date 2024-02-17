import React, { useCallback, useState } from 'react';
import Dialog from '@mui/material/Dialog';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Slide, { SlideProps } from '@mui/material/Slide';
import UserSettingMenu, { MenuItem } from './Menu';
import UserSettingPanel from './SettingPanel';
import { UserSetting } from '$app/stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { useTranslation } from 'react-i18next';
import { UserService } from '$app/application/user/user.service';

const SlideTransition = React.forwardRef((props: SlideProps, ref) => {
  return <Slide {...props} direction='up' ref={ref} />;
});

function UserSettings({ open, onClose }: { open: boolean; onClose: () => void }) {
  const userSettingState = useAppSelector((state) => state.currentUser.userSetting);
  const dispatch = useAppDispatch();
  const { t } = useTranslation();
  const [selected, setSelected] = useState<MenuItem>(MenuItem.Appearance);
  const handleChange = useCallback(
    (setting: Partial<UserSetting>) => {
      const newSetting = { ...userSettingState, ...setting };

      dispatch(currentUserActions.setUserSetting(newSetting));
      const language = newSetting.language || 'en';

      void UserService.setAppearanceSetting({
        theme: newSetting.theme,
        theme_mode: newSetting.themeMode,
        locale: {
          language_code: language.split('-')[0],
          country_code: language.split('-')[1],
        },
      });
    },
    [dispatch, userSettingState]
  );

  return (
    <Dialog
      onMouseDown={(e) => e.stopPropagation()}
      open={open}
      TransitionComponent={SlideTransition}
      keepMounted={false}
      onClose={onClose}
    >
      <DialogTitle className={'text-sm'}>{t('settings.title')}</DialogTitle>
      <DialogContent className={'flex w-[540px]'}>
        <UserSettingMenu
          onSelect={(selected) => {
            setSelected(selected);
          }}
          selected={selected}
        />
        <UserSettingPanel onChange={handleChange} userSettingState={userSettingState} selected={selected} />
      </DialogContent>
    </Dialog>
  );
}

export default UserSettings;
