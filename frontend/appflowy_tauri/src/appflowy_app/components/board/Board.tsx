import { SettingsSvg } from '../_shared/svg/SettingsSvg';
import { SearchInput } from '../_shared/SearchInput';
import { useDatabase } from '../_shared/Database.hooks';
import { BoardBlock } from './BoardBlock';
import { NewBoardBlock } from './NewBoardBlock';
import { IDatabaseRow } from '../../stores/reducers/database/slice';
import { useBoard } from './Board.hooks';

export const Board = ({ databaseId }: { databaseId: string }) => {
  const { database, newField, renameField, newRow } = useDatabase();
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
          {database &&
            boardColumns?.map((column, index) => (
              <BoardBlock
                key={index}
                title={column.title}
                groupingFieldId={groupingFieldId}
                count={column.rows.length}
                fields={database.fields}
                columns={database.columns}
                rows={column.rows}
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
