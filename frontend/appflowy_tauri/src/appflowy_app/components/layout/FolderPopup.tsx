import { MouseEventHandler, useEffect } from 'react';
import { IPopupItem, Popup } from '../_shared/Popup';
import { EditSvg } from '../_shared/EditSvg';
import { TrashSvg } from '../_shared/TrashSvg';
import { CopySvg } from '../_shared/CopySvg';

export const FolderPopup = ({
  onRenameClick,
  onDeleteClick,
  onDuplicateClick,
  onClose,
}: {
  onRenameClick: MouseEventHandler<HTMLButtonElement>;
  onDeleteClick: MouseEventHandler<HTMLButtonElement>;
  onDuplicateClick: MouseEventHandler<HTMLButtonElement>;
  onClose?: () => void;
}) => {
  const items: IPopupItem[] = [
    {
      icon: (
        <i className={'w-[16px] h-[16px] text-black'}>
          <EditSvg></EditSvg>
        </i>
      ),
      onClick: onRenameClick,
      title: 'Rename',
    },
    {
      icon: (
        <i className={'w-[16px] h-[16px] text-black'}>
          <TrashSvg></TrashSvg>
        </i>
      ),
      onClick: onDeleteClick,
      title: 'Delete',
    },
    {
      icon: (
        <i className={'w-[16px] h-[16px] text-black'}>
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
      className={'absolute right-0 top-full z-10'}
    ></Popup>
  );
};
