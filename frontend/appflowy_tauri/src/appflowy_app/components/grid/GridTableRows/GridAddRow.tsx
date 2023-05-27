import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import AddSvg from '../../_shared/svg/AddSvg';
import { useGridAddRow } from './GridAddRow.hooks';
import { useTranslation } from 'react-i18next';
export const GridAddRow = ({ controller }: { controller: DatabaseController }) => {
  const { addRow } = useGridAddRow(controller);
  const { t } = useTranslation();

  return (
    <div>
      <button className='flex cursor-pointer items-center text-gray-500 hover:text-black' onClick={addRow}>
        <i className='mr-2 h-5 w-5'>
          <AddSvg />
        </i>
        <span>{t('grid.row.newRow')}</span>
      </button>
    </div>
  );
};
