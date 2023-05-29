import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';

import AddSvg from '../../_shared/svg/AddSvg';
import { useGridTableHeaderHooks } from './GridTableHeader.hooks';

import { GridTableHeaderItem } from './GridTableHeaderItem';
import { useTranslation } from 'react-i18next';

export const GridTableHeader = ({ controller }: { controller: DatabaseController }) => {
  const { fields, onAddField } = useGridTableHeaderHooks(controller);
  const { t } = useTranslation();

  return (
    <>
      <thead>
        <tr>
          {fields.map((field, i) => {
            return <GridTableHeaderItem field={field} controller={controller} key={i} />;
          })}

          <th className='m-0 w-40 border border-r-0 border-shade-6 p-0'>
            <div
              className='flex cursor-pointer items-center px-4 py-2 text-shade-3 hover:bg-main-secondary hover:text-black'
              onClick={onAddField}
            >
              <i className='mr-2 h-5 w-5'>
                <AddSvg />
              </i>
              <span>{t('grid.field.newColumn')}</span>
            </div>
          </th>
        </tr>
      </thead>
    </>
  );
};
