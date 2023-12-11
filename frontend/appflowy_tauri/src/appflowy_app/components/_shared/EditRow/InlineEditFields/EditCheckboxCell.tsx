import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';

export const EditCheckboxCell = ({ data, onToggle }: { data: 'Yes' | 'No' | undefined; onToggle: () => void }) => {
  // const toggleValue = async () => {
  //   if (data === 'Yes') {
  //     await cellController?.saveCellData('No');
  //   } else {
  //     await cellController?.saveCellData('Yes');
  //   }
  // };

  return (
    <div onClick={() => onToggle()} className={'block px-4 py-1'}>
      <button className={'h-5 w-5'}>
        {data === 'Yes' ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
      </button>
    </div>
  );
};
