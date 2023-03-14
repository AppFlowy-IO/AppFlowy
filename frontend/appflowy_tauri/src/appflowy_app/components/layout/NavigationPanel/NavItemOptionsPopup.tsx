import { IPopupItem, Popup } from '../../_shared/Popup';
import { EditSvg } from '../../_shared/svg/EditSvg';
import { TrashSvg } from '../../_shared/svg/TrashSvg';
import { CopySvg } from '../../_shared/svg/CopySvg';

export const NavItemOptionsPopup = ({
  onRenameClick,
  onDeleteClick,
  onDuplicateClick,
  onClose,
  top,
}: {
  onRenameClick: () => void;
  onDeleteClick: () => void;
  onDuplicateClick: () => void;
  onClose?: () => void;
  top: number;
}) => {
  const items: IPopupItem[] = [
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <EditSvg></EditSvg>
        </i>
      ),
      onClick: onRenameClick,
      title: 'Rename',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <TrashSvg></TrashSvg>
        </i>
      ),
      onClick: onDeleteClick,
      title: 'Delete',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <CopySvg></CopySvg>
        </i>
      ),
      onClick: onDuplicateClick,
      title: 'Duplicate',
    },
  ];

  return (
    <Popup
      onOutsideClick={() => onClose && onClose()}
      items={items}
      className={`absolute right-0`}
      style={{ top: `${top}px` }}
    ></Popup>
  );
};
