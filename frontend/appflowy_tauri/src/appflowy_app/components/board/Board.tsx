import { SettingsSvg } from '../_shared/svg/SettingsSvg';
import { SearchInput } from '../_shared/SearchInput';
import { BoardBlock } from './BoardBlock';
import { NewBoardBlock } from './NewBoardBlock';
import { useBoard } from './Board.hooks';
import { useDatabase } from '../_shared/database-hooks/useDatabase';

export const Board = ({ viewId }: { viewId: string }) => {
  const { controller, rows } = useDatabase(viewId);

  const {
    title,
    boardColumns,
    groupingFieldId,
    changeGroupingField,
    startMove,
    endMove,
    onGhostItemMove,
    movingRowId,
    ghostLocation,
  } = useBoard();

  return (
    <>
      <div className='flex w-full items-center justify-between'>
        <div className={'flex items-center text-xl font-semibold'}>
          <div>{title}</div>
          <button className={'ml-2 h-5 w-5'}>
            <SettingsSvg></SettingsSvg>
          </button>
        </div>

        <div className='flex shrink-0 items-center gap-4'>
          <SearchInput />
        </div>
      </div>
      <div className={'relative w-full flex-1 overflow-auto'}>
        <div className={'absolute flex h-full flex-shrink-0 items-start justify-start gap-4'}>
          {controller &&
            boardColumns?.map((column, index) => (
              <BoardBlock
                viewId={viewId}
                controller={controller}
                key={index}
                title={column.title}
                rows={rows}
                groupingFieldId={groupingFieldId}
                startMove={startMove}
                endMove={endMove}
              />
            ))}

          <NewBoardBlock onClick={() => console.log('new block')}></NewBoardBlock>
        </div>
      </div>
    </>
  );
};
