import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';

export const EditCheckboxCell = ({
  data,
  cellController,
}: {
  data: boolean | undefined;
  cellController: CellController<any, any>;
}) => {
  const toggleValue = async () => {
    await cellController?.saveCellData(!data);
  };

  return (
    <div onClick={() => toggleValue()} className={'block px-4 py-2'}>
      <button className={'h-5 w-5'}>
        {data ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
      </button>
    </div>
  );
};
