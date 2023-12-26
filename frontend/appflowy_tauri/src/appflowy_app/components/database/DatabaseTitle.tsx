import { FormEventHandler, useCallback } from 'react';
import { t } from 'i18next';
import { useViewId } from '$app/hooks';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { updatePageName } from '$app_reducers/pages/async_actions';

export const DatabaseTitle = () => {
  const viewId = useViewId();
  const pageName = useAppSelector((state) => state.pages.pageMap[viewId].name);
  const dispatch = useAppDispatch();

  const handleInput = useCallback<FormEventHandler>(
    (event) => {
      const newTitle = (event.target as HTMLInputElement).value;

      void dispatch(updatePageName({ id: viewId, name: newTitle }));
    },
    [viewId, dispatch]
  );

  return (
    <div className='mb-6 h-[70px] px-16 pt-8'>
      <input
        className='text-3xl font-semibold'
        value={pageName}
        placeholder={t('grid.title.placeholder')}
        onInput={handleInput}
      />
    </div>
  );
};
