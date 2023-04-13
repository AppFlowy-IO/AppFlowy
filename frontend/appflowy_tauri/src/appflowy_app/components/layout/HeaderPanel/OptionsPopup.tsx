import { IPopupItem, PopupSelect } from '../../_shared/PopupSelect';
import { LogoutSvg } from '../../_shared/svg/LogoutSvg';

export const OptionsPopup = ({ onSignOutClick, onClose }: { onSignOutClick: () => void; onClose: () => void }) => {
  const items: IPopupItem[] = [
    {
      title: 'Sign out',
      icon: (
        <i className={'block h-5 w-5 flex-shrink-0'}>
          <LogoutSvg></LogoutSvg>
        </i>
      ),
      onClick: onSignOutClick,
    },
  ];
  return (
    <PopupSelect
      className={'absolute top-[50px] right-[30px] z-10 whitespace-nowrap'}
      items={items}
      onOutsideClick={onClose}
    ></PopupSelect>
  );
};
