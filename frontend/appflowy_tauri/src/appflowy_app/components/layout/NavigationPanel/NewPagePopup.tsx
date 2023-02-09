import { IPopupItem, Popup } from '../../_shared/Popup';
import { DocumentSvg } from '../../_shared/svg/DocumentSvg';
import { BoardSvg } from '../../_shared/svg/BoardSvg';
import { GridSvg } from '../../_shared/svg/GridSvg';

export const NewPagePopup = ({
  onDocumentClick,
  onGridClick,
  onBoardClick,
  onClose,
}: {
  onDocumentClick: () => void;
  onGridClick: () => void;
  onBoardClick: () => void;
  onClose?: () => void;
}) => {
  const items: IPopupItem[] = [
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <DocumentSvg></DocumentSvg>
        </i>
      ),
      onClick: onDocumentClick,
      title: 'Document',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <BoardSvg></BoardSvg>
        </i>
      ),
      onClick: onBoardClick,
      title: 'Board',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
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
