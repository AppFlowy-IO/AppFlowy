import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';
import { FieldType } from '@/application/database-yjs';
import { CellProps, CheckboxCell as CheckboxCellType } from '@/application/database-yjs/cell.type';

export function CheckboxCell({ cell, style }: CellProps<CheckboxCellType>) {
  const checked = cell?.data;

  if (cell && cell?.fieldType !== FieldType.Checkbox) return null;

  return (
    <div style={style} className='relative flex w-full items-center text-lg text-fill-default'>
      {checked ? <CheckboxCheckSvg className={'h-5 w-5'} /> : <CheckboxUncheckSvg className={'h-5 w-5'} />}
    </div>
  );
}
