import { t } from 'i18next';
import AddSvg from '../../_shared/svg/AddSvg';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { MouseEventHandler, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';

import { DatabaseFilterItem } from '$app/components/_shared/DatabaseFilter/DatabaseFilterItem';
import { databaseActions, IDatabaseFilter } from '$app_reducers/database/slice';

export const DatabaseFilterPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const refContainer = useRef<HTMLDivElement>(null);

  useOutsideClick(refContainer, onOutsideClick);

  // stores
  const filters = useAppSelector((state) => state.database.filters);
  const dispatch = useAppDispatch();

  const [showBlankFilter, setShowBlankFilter] = useState(filters.length === 0);

  const onAddClick: MouseEventHandler = () => {
    setShowBlankFilter(true);
  };

  const onSaveFilterItem = (filter: IDatabaseFilter) => {
    dispatch(databaseActions.upsertFilter({ filter }));
    setShowBlankFilter(false);
  };

  const onDeleteFilterItem = (filter: IDatabaseFilter | null) => {
    if (!filter) return;
    if (filters.length === 1) setShowBlankFilter(true);
    dispatch(databaseActions.removeFilter({ filter }));
  };

  return (
    <>
      <div className={'fixed inset-0 z-10 backdrop-blur-sm'}></div>

      <div className={'fixed inset-0 z-10 flex items-center justify-center overflow-y-auto'}>
        <div className='flex flex-col rounded-lg bg-white shadow-md' ref={refContainer}>
          <div className='px-6 pt-6 text-sm text-shade-3'>{t('grid.settings.filter')}</div>

          <div className='flex flex-col gap-3 overflow-y-scroll px-6 py-6 text-sm'>
            {filters.map((filter, index: number) => (
              <DatabaseFilterItem
                data={filter}
                onSave={onSaveFilterItem}
                onDelete={() => onDeleteFilterItem(filter)}
                key={index}
                index={index}
              ></DatabaseFilterItem>
            ))}
            {/* null row represents new filter */}
            {showBlankFilter && (
              <DatabaseFilterItem data={null} onSave={onSaveFilterItem} index={filters.length}></DatabaseFilterItem>
            )}
          </div>

          <hr />

          <button onClick={onAddClick} className='flex cursor-pointer items-center gap-2 px-6 py-6 text-sm text-shade-1'>
            <div className='h-5 w-5'>
              <AddSvg />
            </div>
            {t('grid.settings.addFilter')}
          </button>
        </div>
      </div>
    </>
  );
};
