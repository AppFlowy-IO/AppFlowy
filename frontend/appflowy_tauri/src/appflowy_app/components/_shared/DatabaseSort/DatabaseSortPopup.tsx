import { t } from 'i18next';
import { MouseEventHandler, useMemo, useRef, useState } from 'react';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import { useAppSelector } from '$app/stores/store';
import { IDatabaseSort } from '$app_reducers/database/slice';
import { DatabaseSortItem } from '$app/components/_shared/DatabaseSort/DatabaseSortItem';
import AddSvg from '$app/components/_shared/svg/AddSvg';
import { SortController } from '$app/stores/effects/database/sort/sort_controller';

export const DatabaseSortPopup = ({
  sortController,
  onOutsideClick,
}: {
  sortController: SortController;
  onOutsideClick: () => void;
}) => {
  const refContainer = useRef<HTMLDivElement>(null);

  useOutsideClick(refContainer, onOutsideClick);

  // stores
  const sortStore = useAppSelector((state) => state.database.sort);
  const [sort, setSort] = useState<(IDatabaseSort | null)[]>(sortStore);

  const [showBlankSort, setShowBlankSort] = useState(sortStore.length === 0);

  const onSaveSortItem = async (sortItem: IDatabaseSort) => {
    let updatedSort = sortItem;

    if (sortItem.id) {
      await sortController.updateSort(sortItem.id, sortItem.fieldId, sortItem.fieldType, sortItem.order);
    } else {
      const newId = await sortController.addSort(sortItem.fieldId, sortItem.fieldType, sortItem.order);

      updatedSort = { ...updatedSort, id: newId };
    }

    // update local copy
    const index = sort.findIndex((s) => s?.fieldId === sortItem.fieldId);

    if (index === -1) {
      setSort([...sort, updatedSort]);
    } else {
      setSort([...sort.slice(0, index), updatedSort, ...sort.slice(index + 1)]);
    }

    setShowBlankSort(false);
  };

  const onDeleteClick = async (sortItem: IDatabaseSort | null) => {
    if (!sortItem || !sortItem.id) return;

    // add blank sort if no sorts left
    if (sort.length === 1) {
      setShowBlankSort(true);
    }

    await sortController.removeSort(sortItem.fieldId, sortItem.fieldType, sortItem.id);

    const index = sort.findIndex((s) => s?.fieldId === sortItem.fieldId);

    setSort([...sort.slice(0, index), ...sort.slice(index + 1)]);
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
          <div className='text-shade-3 px-6 pt-6 text-sm'>{t('grid.settings.sort')}</div>

          <div className='flex flex-col gap-3 overflow-y-scroll px-6 py-6 text-sm'>
            {rows.map((sortItem, index) => (
              <DatabaseSortItem
                key={index}
                data={sortItem}
                onSave={onSaveSortItem}
                onDelete={() => onDeleteClick(sortItem)}
              />
            ))}
          </div>

          <hr />

          <button onClick={onAddClick} className='text-shade-1 flex cursor-pointer items-center gap-2 px-6 py-6 text-sm'>
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
