import { CloseSvg } from '$app/components/_shared/svg/CloseSvg';
import { useRow } from '$app/components/_shared/database-hooks/useRow';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { EditBoardCell } from '$app/components/board/EditBoardRow/EditBoardCell';

export const EditBoardRow = ({
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
  const { cells } = useRow(viewId, controller, rowInfo);

  return (
    <div className={'fixed inset-0 z-20 flex items-center justify-center bg-black/30 backdrop-blur-sm'}>
      <div className={'relative flex min-w-[70%] flex-col gap-8 rounded-xl bg-white p-8'}>
        <div onClick={() => onClose()} className={'absolute top-4 right-4'}>
          <button className={'block h-8 w-8 rounded-lg text-shade-2 hover:bg-main-secondary'}>
            <CloseSvg></CloseSvg>
          </button>
        </div>
        <div className={'flex flex-col gap-4'}>
          {cells.map((cell, cellIndex) => (
            <EditBoardCell
              key={cellIndex}
              cellIdentifier={cell.cellIdentifier}
              cellCache={controller.databaseViewCache.getRowCache().getCellCache()}
              fieldController={controller.fieldController}
            ></EditBoardCell>
          ))}
        </div>
      </div>
    </div>
  );
};
