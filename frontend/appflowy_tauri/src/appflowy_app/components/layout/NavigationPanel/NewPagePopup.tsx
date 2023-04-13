import { IPopupItem, PopupSelect } from '../../_shared/PopupSelect';
import { DocumentSvg } from '../../_shared/svg/DocumentSvg';
import { BoardSvg } from '../../_shared/svg/BoardSvg';
import { GridSvg } from '../../_shared/svg/GridSvg';

export const NewPagePopup = ({
  onDocumentClick,
  onGridClick,
  onBoardClick,
  onClose,
  top,
}: {
  onDocumentClick: () => void;
  onGridClick: () => void;
  onBoardClick: () => void;
  onClose?: () => void;
  top: number;
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
    <PopupSelect
      onOutsideClick={() => onClose && onClose()}
      items={items}
      className={'absolute right-0'}
      style={{ top: `${top}px` }}
    ></PopupSelect>
  );
};
