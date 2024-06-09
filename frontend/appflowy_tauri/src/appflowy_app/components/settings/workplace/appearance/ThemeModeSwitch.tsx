import { useTranslation } from 'react-i18next';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useCallback, useMemo } from 'react';
import { ThemeModePB } from '@/services/backend';
import darkSrc from '$app/assets/settings/dark.png';
import lightSrc from '$app/assets/settings/light.png';
import { currentUserActions, ThemeMode } from '$app_reducers/current-user/slice';
import { UserService } from '$app/application/user/user.service';
import { ReactComponent as CheckCircle } from '$app/assets/settings/check_circle.svg';

export const ThemeModeSwitch = () => {
  const { t } = useTranslation();
  const userSettingState = useAppSelector((state) => state.currentUser.userSetting);
  const dispatch = useAppDispatch();

  const selectedMode = userSettingState.themeMode;
  const themeModes = useMemo(() => {
    return [
      {
        name: t('newSettings.workplace.appearance.themeMode.auto'),
        value: ThemeModePB.System,
        img: (
          <div className={'relative h-[67px] overflow-hidden'}>
            <img className={'h-[67px] w-[71px]'} src={darkSrc} />
            <img className={'absolute left-1/2 top-0'} src={lightSrc} />
          </div>
        ),
      },
      {
        name: t('newSettings.workplace.appearance.themeMode.light'),
        value: ThemeModePB.Light,
        img: <img src={lightSrc} className={'h-[67px] w-[71px]'} />,
      },
      {
        name: t('newSettings.workplace.appearance.themeMode.dark'),
        value: ThemeModePB.Dark,
        img: <img src={darkSrc} className={'h-[67px] w-[71px]'} />,
      },
    ];
  }, [t]);

  const handleChange = useCallback(
    (newValue: ThemeModePB) => {
      const newSetting = {
        ...userSettingState,
        ...{
          themeMode: newValue,
          isDark:
            newValue === ThemeMode.Dark ||
            (newValue === ThemeMode.System && window.matchMedia('(prefers-color-scheme: dark)').matches),
        },
      };

      dispatch(currentUserActions.setUserSetting(newSetting));

      void UserService.setAppearanceSetting({
        theme_mode: newSetting.themeMode,
      });
    },
    [dispatch, userSettingState]
  );

  const renderThemeModeItem = useCallback(
    (option: { name: string; value: ThemeModePB; img: JSX.Element }) => {
      return (
        <div
          key={option.value}
          onClick={() => handleChange(option.value)}
          className={'flex cursor-pointer flex-col items-center gap-2'}
        >
          <div
            style={{
              borderColor: selectedMode === option.value ? 'var(--text-title)' : 'var(--line-border)',
            }}
            className={'theme-mode-item'}
          >
            {option.img}
            <CheckCircle
              className={'absolute left-0.5 top-0.5 h-4 w-4'}
              style={{
                display: selectedMode === option.value ? 'block' : 'none',
              }}
            />
          </div>
          <div className={'text-sm text-text-title'}>{option.name}</div>
        </div>
      );
    },
    [handleChange, selectedMode]
  );

  return <div className={'flex gap-3'}>{themeModes.map((mode) => renderThemeModeItem(mode))}</div>;
};
