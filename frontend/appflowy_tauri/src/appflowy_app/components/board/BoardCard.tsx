import { Details2Svg } from '../_shared/svg/Details2Svg';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { useRow } from '../_shared/database-hooks/useRow';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { BoardCell } from './BoardCell';
import { Draggable } from 'react-beautiful-dnd';
import { MouseEventHandler, useState } from 'react';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { RowBackendService } from '$app/stores/effects/database/row/row_bd_svc';
import { useTranslation } from 'react-i18next';
import { useAppSelector } from '$app/stores/store';

export const BoardCard = ({
  index,
  viewId,
  controller,
  rowInfo,
  groupByFieldId,
  onOpenRow,
}: {
  index: number;
  viewId: string;
  controller: DatabaseController;
  rowInfo: RowInfo;
  groupByFieldId: string;
  onOpenRow: (rowId: RowInfo) => void;
}) => {
  const databaseStore = useAppSelector((state) => state.database);
  const { t } = useTranslation();

  const { cells } = useRow(viewId, controller, rowInfo);

  const [showCardPopup, setShowCardPopup] = useState(false);
  const [cardPopupLeft, setCardPopupLeft] = useState(0);
  const [cardPopupTop, setCardPopupTop] = useState(0);

  const onDetailClick: MouseEventHandler = (e) => {
    e.stopPropagation();
    let target = e.target as HTMLElement;

    while (!(target instanceof HTMLButtonElement)) {
      if (target.parentElement === null) return;
      target = target.parentElement;
    }

    const { right: left, top } = target.getBoundingClientRect();
    setCardPopupLeft(left);
    setCardPopupTop(top);
    setShowCardPopup(true);
  };

  const onDeleteRowClick = async () => {
    setShowCardPopup(false);
    const svc = new RowBackendService(viewId);
    await svc.deleteRow(rowInfo.row.id);
  };

  return (
    <>
      <Draggable draggableId={rowInfo.row.id} key={rowInfo.row.id} index={index}>
        {(provided) => (
          <div
            ref={provided.innerRef}
            {...provided.draggableProps}
            {...provided.dragHandleProps}
            onClick={() => onOpenRow(rowInfo)}
            className={`relative cursor-pointer select-none rounded-lg border border-shade-6 bg-white px-3 py-2 transition-transform duration-100 hover:bg-main-selector `}
          >
            <button onClick={onDetailClick} className={'absolute right-4 top-2.5 h-5 w-5 rounded hover:bg-surface-2'}>
              <Details2Svg></Details2Svg>
            </button>
            <div className={'flex flex-col gap-3'}>
              {cells
                .filter(
                  (cell) => cell.fieldId !== groupByFieldId && databaseStore.fields[cell.cellIdentifier.fieldId].visible
                )
                .map((cell, cellIndex) => (
                  <BoardCell
                    key={cellIndex}
                    cellIdentifier={cell.cellIdentifier}
                    cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
                    fieldController={controller.fieldController}
                  ></BoardCell>
                ))}
            </div>
          </div>
        )}
      </Draggable>
      {showCardPopup && (
        <PopupWindow
          className={'p-2 text-xs'}
          onOutsideClick={() => setShowCardPopup(false)}
          left={cardPopupLeft}
          top={cardPopupTop}
        >
          <button
            key={index}
            className={'flex w-full cursor-pointer items-center gap-2 rounded-lg px-2 py-2 hover:bg-main-secondary'}
            onClick={() => onDeleteRowClick()}
          >
            <i className={'h-5 w-5'}>
              <TrashSvg></TrashSvg>
            </i>
            <span className={'flex-shrink-0'}>{t('grid.row.delete')}</span>
          </button>
        </PopupWindow>
      )}
    </>
  );
};
