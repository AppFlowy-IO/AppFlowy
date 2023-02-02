import { MouseEventHandler, useEffect } from 'react';
import { IPopupItem, Popup } from '../_shared/Popup';
import { DocumentSvg } from '../_shared/DocumentSvg';
import { BoardSvg } from '../_shared/BoardSvg';
import { GridSvg } from '../_shared/GridSvg';

export const NewPagePopup = ({
  onDocumentClick,
  onGridClick,
  onBoardClick,
  onClose,
}: {
  onDocumentClick: MouseEventHandler<HTMLButtonElement>;
  onGridClick: MouseEventHandler<HTMLButtonElement>;
  onBoardClick: MouseEventHandler<HTMLButtonElement>;
  onClose?: () => void;
}) => {
  const items: IPopupItem[] = [
    {
      icon: (
        <i className={'w-[16px] h-[16px] text-black'}>
          <DocumentSvg></DocumentSvg>
        </i>
      ),
      onClick: onDocumentClick,
      title: 'Document',
    },
    {
      icon: (
        <i className={'w-[16px] h-[16px] text-black'}>
          <BoardSvg></BoardSvg>
        </i>
      ),
      onClick: onBoardClick,
      title: 'Board',
    },
    {
      icon: (
        <i className={'w-[16px] h-[16px] text-black'}>
          <GridSvg></GridSvg>
        </i>
      ),
      onClick: onGridClick,
      title: 'Grid',
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
