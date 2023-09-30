import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import AddSvg from '../../_shared/svg/AddSvg';
import { useGridTableHeaderHooks } from './GridTableHeader.hooks';
import { GridTableHeaderItem } from './GridTableHeaderItem';
import { useTranslation } from 'react-i18next';
import { useAppSelector } from '$app/stores/store';

export const GridTableHeader = ({
  controller,
  onShowFilterClick,
  onShowSortClick,
}: {
  controller: DatabaseController;
  onShowFilterClick: () => void;
  onShowSortClick: () => void;
}) => {
  const columns = useAppSelector((state) => state.database.columns);
  const fields = useAppSelector((state) => state.database.fields);
  const { onAddField } = useGridTableHeaderHooks(controller);
  const { t } = useTranslation();

  return (
    <div className={'flex select-none text-xs'} style={{ userSelect: 'none' }}>
      <div className={'w-7 flex-shrink-0'}></div>
      {columns
        .filter((column) => column.visible)
        .map((column, i) => {
          return (
            <GridTableHeaderItem
              onShowFilterClick={onShowFilterClick}
              onShowSortClick={onShowSortClick}
              field={fields[column.fieldId]}
              controller={controller}
              key={i}
              index={i}
            />
          );
        })}
      <div
        onClick={onAddField}
        className='-ml-1.5 flex w-40 flex-shrink-0 cursor-pointer items-center border-b border-t border-line-divider px-4 py-2 text-text-caption hover:bg-fill-list-hover hover:text-text-title'
      >
        <i className='mr-2 h-5 w-5'>
          <AddSvg />
        </i>
        <span className={'whitespace-nowrap'}>{t('grid.field.newProperty')}</span>
      </div>
    </div>
  );
};
