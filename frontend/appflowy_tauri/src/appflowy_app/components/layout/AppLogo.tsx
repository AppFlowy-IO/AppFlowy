import { HideMenuSvg } from '../_shared/svg/HideMenuSvg';
import { ShowMenuSvg } from '../_shared/svg/ShowMenuSvg';

export const AppLogo = ({
  iconToShow,
  onHideMenuClick,
  onShowMenuClick,
}: {
  iconToShow: 'hide' | 'show';
  onHideMenuClick?: () => void;
  onShowMenuClick?: () => void;
}) => {
  return (
    <div className={'mb-2 flex h-[60px] items-center justify-between px-6'}>
      <img src={'/images/flowy_logo_with_text.svg'} alt={'logo'} />
      {iconToShow === 'hide' && (
        <button onClick={onHideMenuClick} className={'h-5 w-5'}>
          <i>
            <HideMenuSvg></HideMenuSvg>
          </i>
        </button>
      )}
      {iconToShow === 'show' && (
        <button onClick={onShowMenuClick} className={'h-5 w-5'}>
          <i>
            <ShowMenuSvg></ShowMenuSvg>
          </i>
        </button>
      )}
    </div>
  );
};
