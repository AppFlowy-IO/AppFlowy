import { HideMenuSvg } from '../_shared/svg/HideMenuSvg';
import { ShowMenuSvg } from '../_shared/svg/ShowMenuSvg';
import { useAppSelector } from '$app/stores/store';
import { ThemeMode } from '$app/interfaces';
import { AppflowyLogoLight } from '$app/components/_shared/svg/AppflowyLogoLight';
import { AppflowyLogoDark } from '$app/components/_shared/svg/AppflowyLogoDark';

export const AppLogo = ({
  iconToShow,
  onHideMenuClick,
  onShowMenuClick,
}: {
  iconToShow: 'hide' | 'show';
  onHideMenuClick?: () => void;
  onShowMenuClick?: () => void;
}) => {
  const isDark = useAppSelector((state) => state.currentUser?.userSetting?.themeMode === ThemeMode.Dark);

  return (
    <div className={'mb-2 flex h-[60px] items-center justify-between px-6 text-text-title'}>
      {isDark ? <AppflowyLogoDark /> : <AppflowyLogoLight />}

      {iconToShow === 'hide' && (
        <button onClick={onHideMenuClick} className={'h-5 w-5'}>
          <i>
            <HideMenuSvg></HideMenuSvg>
          </i>
        </button>
      )}
      {iconToShow === 'show' && (
        <button onClick={onShowMenuClick} className={'h-5 w-5 text-text-title'}>
          <i>
            <ShowMenuSvg></ShowMenuSvg>
          </i>
        </button>
      )}
    </div>
  );
};
