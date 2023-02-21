import { SettingsSvg } from '../_shared/svg/SettingsSvg';
import { SearchInput } from '../_shared/SearchInput';
import { useDatabase } from '../_shared/Database.hooks';
import { BoardBlock } from './BoardBlock';
import { NewBoardBlock } from './NewBoardBlock';
import { IDatabaseRow } from '../../stores/reducers/database/slice';
import { useBoard } from './Board.hooks';

export const Board = ({ databaseId }: { databaseId: string }) => {
  const { database, newField, renameField, newRow } = useDatabase(databaseId);
  const { groupingFieldId, changeGroupingField } = useBoard(databaseId);

  return (
    <>
      <div className='flex w-full items-center justify-between'>
        <div className={'flex items-center text-xl font-semibold'}>
          <div>{database?.title}</div>
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
          {database?.fields[groupingFieldId].fieldOptions.selectOptions?.map((groupFieldItem, index) => {
            const rows = database?.rows.filter((row) =>
              row.cells[groupingFieldId].optionIds?.some((so) => so === groupFieldItem.selectOptionId)
            );
            return (
              <BoardBlock
                key={index}
                title={groupFieldItem.title}
                groupingFieldId={groupingFieldId}
                count={rows.length}
                fields={database?.fields}
                columns={database?.columns}
                rows={rows}
              />
            );
          })}

          <NewBoardBlock onClick={() => console.log('new block')}></NewBoardBlock>
        </div>
      </div>
    </>
  );
};
