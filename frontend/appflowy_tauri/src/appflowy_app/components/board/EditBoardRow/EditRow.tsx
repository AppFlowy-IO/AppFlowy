import { CloseSvg } from '$app/components/_shared/svg/CloseSvg';
import { useRow } from '$app/components/_shared/database-hooks/useRow';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { EditCellWrapper } from '$app/components/board/EditBoardRow/EditCellWrapper';
import AddSvg from '$app/components/_shared/svg/AddSvg';

export const EditRow = ({
  onClose,
  viewId,
  controller,
  rowInfo,
}: {
  onClose: () => void;
  viewId: string;
  controller: DatabaseController;
  rowInfo: RowInfo;
}) => {
  const { cells, onNewColumnClick } = useRow(viewId, controller, rowInfo);

  return (
    <div className={'fixed inset-0 z-20 flex items-center justify-center bg-black/30 backdrop-blur-sm'}>
      <div className={'relative flex min-h-[50%] min-w-[70%] flex-col gap-8 rounded-xl bg-white px-8 pb-4 pt-12'}>
        <div onClick={() => onClose()} className={'absolute top-4 right-4'}>
          <button className={'block h-8 w-8 rounded-lg text-shade-2 hover:bg-main-secondary'}>
            <CloseSvg></CloseSvg>
          </button>
        </div>
        <div className={'flex flex-1 flex-col gap-4'}>
          {cells.map((cell, cellIndex) => (
            <EditCellWrapper
              key={cellIndex}
              cellIdentifier={cell.cellIdentifier}
              cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
              fieldController={controller.fieldController}
            ></EditCellWrapper>
          ))}
        </div>
        <div className={'border-t border-shade-6 pt-2'}>
          <button
            onClick={() => onNewColumnClick()}
            className={'flex w-full items-center gap-2 rounded-lg px-4 py-2 hover:bg-shade-6'}
          >
            <i className={'h-5 w-5'}>
              <AddSvg></AddSvg>
            </i>
            <span>New Column</span>
          </button>
        </div>
      </div>
    </div>
  );
};
