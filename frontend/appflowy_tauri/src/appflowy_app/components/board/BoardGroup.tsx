import { Details2Svg } from '../_shared/svg/Details2Svg';
import AddSvg from '../_shared/svg/AddSvg';
import { BoardCard } from './BoardCard';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { Droppable } from 'react-beautiful-dnd';
import { DatabaseGroupController } from '$app/stores/effects/database/group/group_controller';
import { useTranslation } from 'react-i18next';
import { useEffect, useState } from 'react';

export const BoardGroup = ({
  viewId,
  controller,
  groupByFieldId,
  onNewRowClick,
  onOpenRow,
  group,
}: {
  viewId: string;
  controller: DatabaseController;
  groupByFieldId: string;
  onNewRowClick: () => void;
  onOpenRow: (rowId: RowInfo) => void;
  group: DatabaseGroupController;
}) => {
  const { t } = useTranslation();

  const [rows, setRows] = useState<RowInfo[]>([]);
  useEffect(() => {
    const reloadRows = () => {
      setRows(group.rows.map((rowPB) => new RowInfo(viewId, controller.fieldController.fieldInfos, rowPB)));
    };
    reloadRows();
    group.subscribe({
      onRemoveRow: reloadRows,
      onInsertRow: reloadRows,
      onUpdateRow: reloadRows,
      onCreateRow: reloadRows,
    });
    return () => {
      group.unsubscribe();
    };
  }, [controller, group, viewId]);

  return (
    <div className={'flex h-full w-[250px] flex-col rounded-lg bg-surface-1'}>
      <div className={'flex items-center justify-between p-4'}>
        <div className={'flex items-center gap-2'}>
          <span>{group.name}</span>
          <span className={'text-shade-4'}>({group.rows.length})</span>
        </div>
        <div className={'flex items-center gap-2'}>
          <button className={'h-5 w-5 rounded hover:bg-surface-2'}>
            <Details2Svg></Details2Svg>
          </button>
          <button className={'h-5 w-5 rounded hover:bg-surface-2'}>
            <AddSvg></AddSvg>
          </button>
        </div>
      </div>
      <Droppable droppableId={group.groupId}>
        {(provided) => (
          <div
            className={'flex flex-1 flex-col gap-1 overflow-auto px-2'}
            {...provided.droppableProps}
            ref={provided.innerRef}
          >
            {rows.map((row, index) => {
              return (
                <BoardCard
                  viewId={viewId}
                  controller={controller}
                  index={index}
                  key={row.row.id}
                  rowInfo={row}
                  groupByFieldId={groupByFieldId}
                  onOpenRow={onOpenRow}
                ></BoardCard>
              );
            })}
          </div>
        )}
      </Droppable>
      <div className={'p-2'}>
        <button
          onClick={onNewRowClick}
          className={'flex w-full items-center gap-2 rounded-lg px-2 py-2 hover:bg-surface-2'}
        >
          <span className={'h-5 w-5'}>
            <AddSvg></AddSvg>
          </span>
          <span>{t('board.column.create_new_card')}</span>
        </button>
      </div>
    </div>
  );
};
