import { Details2Svg } from '../_shared/svg/Details2Svg';
import AddSvg from '../_shared/svg/AddSvg';
import { BoardCard } from './BoardCard';
import { RowInfo } from '../../stores/effects/database/row/row_cache';
import { DatabaseController } from '../../stores/effects/database/database_controller';
import { Droppable } from 'react-beautiful-dnd';
import { DatabaseGroupController } from '$app/stores/effects/database/group/group_controller';

export const BoardBlock = ({
  viewId,
  controller,
  allRows,
  groupByFieldId,
  onNewRowClick,
  onOpenRow,
  group,
}: {
  viewId: string;
  controller: DatabaseController;
  allRows: readonly RowInfo[];
  groupByFieldId: string;
  onNewRowClick: () => void;
  onOpenRow: (rowId: RowInfo) => void;
  group: DatabaseGroupController;
}) => {
  return (
    <div className={'flex h-full w-[250px] flex-col rounded-lg bg-surface-1'}>
      <div className={'flex items-center justify-between p-4'}>
        <div className={'flex items-center gap-2'}>
          <span>{group.name}</span>
          <span className={'text-shade-4'}>()</span>
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
            {group.rows.map((row_pb, index) => {
              const row = allRows.find((r) => r.row.id === row_pb.id);
              return row ? (
                <BoardCard
                  viewId={viewId}
                  controller={controller}
                  index={index}
                  key={row.row.id}
                  rowInfo={row}
                  groupByFieldId={groupByFieldId}
                  onOpenRow={onOpenRow}
                ></BoardCard>
              ) : (
                <span key={index}></span>
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
          <span>New</span>
        </button>
      </div>
    </div>
  );
};
