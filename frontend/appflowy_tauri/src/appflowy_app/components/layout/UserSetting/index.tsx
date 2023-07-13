import React, { useCallback, useState } from 'react';
import Dialog from '@mui/material/Dialog';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Slide, { SlideProps } from '@mui/material/Slide';
import UserSettingMenu, { MenuItem } from './Menu';
import UserSettingPanel from './SettingPanel';
import { Theme, UserSetting } from '$app/interfaces';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { currentUserActions } from '$app_reducers/current-user/slice';
import { useUserSettingControllerContext } from '$app/components/_shared/app-hooks/useUserSettingControllerContext';
import { ThemeModePB } from '@/services/backend';
import { useTranslation } from 'react-i18next';

const SlideTransition = React.forwardRef((props: SlideProps, ref) => {
  return <Slide {...props} direction='up' ref={ref} />;
});

function UserSettings({ open, onClose }: { open: boolean; onClose: () => void }) {
  const userSettingState = useAppSelector((state) => state.currentUser.userSetting);
  const dispatch = useAppDispatch();
  const userSettingController = useUserSettingControllerContext();
  const { t } = useTranslation();
  const [selected, setSelected] = useState<MenuItem>(MenuItem.Appearance);
  const handleChange = useCallback(
    (setting: Partial<UserSetting>) => {
      const newSetting = { ...userSettingState, ...setting };

      dispatch(currentUserActions.setUserSetting(newSetting));
      if (userSettingController) {
        const language = newSetting.language || 'en';

        userSettingController.setAppearanceSetting({
          theme: newSetting.theme || Theme.Default,
          theme_mode: newSetting.themeMode || ThemeModePB.Light,
          locale: {
            language_code: language.split('-')[0],
            country_code: language.split('-')[1],
          },
        });
      }
    },
    [dispatch, userSettingController, userSettingState]
  );

  return (
    <Dialog
      onMouseDown={(e) => e.stopPropagation()}
      open={open}
      TransitionComponent={SlideTransition}
      keepMounted
      onClose={onClose}
    >
      <DialogTitle>{t('settings.title')}</DialogTitle>
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
