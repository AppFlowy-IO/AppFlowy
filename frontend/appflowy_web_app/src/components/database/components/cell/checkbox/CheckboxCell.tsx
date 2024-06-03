import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';
import { FieldType } from '@/application/database-yjs';
import { CellProps, CheckboxCell as CheckboxCellType } from '@/components/database/components/cell/cell.type';

export function CheckboxCell({ cell, style }: CellProps<CheckboxCellType>) {
  const checked = cell?.data;

  if (cell?.fieldType !== FieldType.Checkbox) return null;

  return (
    <div style={style} className='relative flex w-full cursor-pointer items-center text-lg text-fill-default'>
      {checked ? <CheckboxCheckSvg className={'h-4 w-4'} /> : <CheckboxUncheckSvg className={'h-4 w-4'} />}
    </div>
  );
}
