import { t } from 'i18next';
import { MouseEventHandler, useMemo, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { databaseActions, IDatabaseSort } from '$app_reducers/database/slice';
import { DatabaseSortItem } from '$app/components/_shared/DatabaseSort/DatabaseSortItem';
import AddSvg from '$app/components/_shared/svg/AddSvg';

export const DatabaseSortPopup = ({ onOutsideClick }: { onOutsideClick: () => void }) => {
  const refContainer = useRef<HTMLDivElement>(null);

  useOutsideClick(refContainer, onOutsideClick);

  // stores
  const sortStore = useAppSelector((state) => state.database.sort);
  const dispatch = useAppDispatch();

  const [sort, setSort] = useState<(IDatabaseSort | null)[]>(sortStore);

  const [showBlankSort, setShowBlankSort] = useState(sortStore.length === 0);

  const onSaveClick = (sortItem: IDatabaseSort) => {
    // update global store
    dispatch(databaseActions.upsertSort({ sort: sortItem }));

    // update local copy
    const index = sort.findIndex((s) => s?.fieldId === sortItem.fieldId);

    if (index >= 0) {
      setSort([...sort.slice(0, index), sortItem, ...sort.slice(index + 1)]);
    } else {
      setSort([...sort, sortItem]);
    }

    setShowBlankSort(false);
  };

  const onDeleteClick = (sortItem: IDatabaseSort | null) => {
    if (!sortItem) return;
    // update global store
    dispatch(databaseActions.removeSort({ sort: sortItem }));

    // add blank sort if no sorts left
    if (sort.length === 1) {
      setShowBlankSort(true);
    }

    // update local copy
    const index = sort.findIndex((s) => s?.fieldId === sortItem.fieldId);

    if (index >= 0) {
      setSort([...sort.slice(0, index), ...sort.slice(index + 1)]);
    }
  };

  const onAddClick: MouseEventHandler = () => {
    setShowBlankSort(true);
  };

  const rows = useMemo(() => (showBlankSort ? [...sort, null] : sort), [sort, showBlankSort]);

  return (
    <>
      <div className={'fixed inset-0 z-10 backdrop-blur-sm'}></div>

      <div className={'fixed inset-0 z-10 flex items-center justify-center overflow-y-auto'}>
        <div className='flex flex-col rounded-lg bg-white shadow-md' ref={refContainer}>
          <div className='px-6 pt-6 text-sm text-shade-3'>{t('grid.settings.sort')}</div>

          <div className='flex flex-col gap-3 overflow-y-scroll px-6 py-6 text-sm'>
            {rows.map((sortItem, index) => (
              <DatabaseSortItem
                key={index}
                data={sortItem}
                onSave={onSaveClick}
                onDelete={() => onDeleteClick(sortItem)}
              />
            ))}
          </div>

          <hr />

          <button onClick={onAddClick} className='flex cursor-pointer items-center gap-2 px-6 py-6 text-sm text-shade-1'>
            <div className='h-5 w-5'>
              <AddSvg />
            </div>
            {t('grid.sort.addSort')}
          </button>
        </div>
      </div>
    </>
  );
};
