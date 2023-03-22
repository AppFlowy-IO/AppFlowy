import { SettingsSvg } from '../_shared/svg/SettingsSvg';
import { SearchInput } from '../_shared/SearchInput';
import { BoardBlock } from './BoardBlock';
import { NewBoardBlock } from './NewBoardBlock';
import { useDatabase } from '../_shared/database-hooks/useDatabase';
import { ViewLayoutTypePB } from '@/services/backend';

export const Board = ({ viewId }: { viewId: string }) => {
  const { controller, rows, groups } = useDatabase(viewId, ViewLayoutTypePB.Board);

  return (
    <>
      <div className='flex w-full items-center justify-between'>
        <div className={'flex items-center text-xl font-semibold'}>
          <div>{'Kanban'}</div>
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
            groups &&
            groups.map((group, index) => (
              <BoardBlock
                key={index}
                viewId={viewId}
                controller={controller}
                rows={group.rows}
                title={group.name}
                allRows={rows}
              />
            ))}

          <NewBoardBlock onClick={() => console.log('new block')}></NewBoardBlock>
        </div>
      </div>
    </>
  );
};
