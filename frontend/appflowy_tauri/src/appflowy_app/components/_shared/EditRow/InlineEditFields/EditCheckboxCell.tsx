import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { CheckboxCellController } from '$app/stores/effects/database/cell/controller_builder';

export const EditCheckboxCell = ({
  data,
  cellController,
}: {
  data: 'Yes' | 'No' | undefined;
  cellController: CheckboxCellController;
}) => {
  const toggleValue = async () => {
    if (data === 'Yes') {
      await cellController?.saveCellData('No');
    } else {
      await cellController?.saveCellData('Yes');
    }
  };

  return (
    <div onClick={() => toggleValue()} className={'block px-4 py-1'}>
      <button className={'h-5 w-5'}>
        {data === 'Yes' ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
      </button>
    </div>
  );
};
