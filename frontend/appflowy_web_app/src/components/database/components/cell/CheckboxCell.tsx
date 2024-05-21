import { FieldId } from '@/application/collab.type';
import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';
import { CheckboxCell } from '@/components/database/components/cell/cell.type';

export default function ({ cell }: { cell?: CheckboxCell; rowId: string; fieldId: FieldId }) {
  const checked = cell?.data;

  return (
    <div className='relative flex w-full cursor-pointer items-center text-lg text-fill-default'>
      {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
    </div>
  );
}
