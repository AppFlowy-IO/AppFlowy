import React, { useCallback } from 'react';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { useTranslation } from 'react-i18next';
import { useLocation, useNavigate } from 'react-router-dom';
import { useDrag } from 'src/appflowy_app/components/_shared/drag_block';
import { deletePage } from '$app/application/folder/page.service';

function TrashButton() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const currentPathType = useLocation().pathname.split('/')[1];
  const navigateToTrash = () => {
    navigate('/trash');
  };

  const selected = currentPathType === 'trash';

  const onEnd = useCallback((result: { dragId: string; position: 'before' | 'after' | 'inside' }) => {
    void deletePage(result.dragId);
  }, []);

  const { onDrop, onDragOver, onDragLeave, isDraggingOver } = useDrag({
    onEnd,
  });

  return (
    <div
      onDrop={onDrop}
      onDragOver={onDragOver}
      onDragLeave={onDragLeave}
      data-page-id={'trash'}
      onClick={navigateToTrash}
      className={`mx-1 my-3 flex h-[32px] w-[100%] items-center rounded-lg p-2 hover:bg-fill-list-hover ${
        selected ? 'bg-fill-list-active' : ''
      } ${isDraggingOver ? 'bg-fill-list-hover' : ''}`}
    >
      <div className='h-6 w-6'>
        <TrashSvg />
      </div>
      <span className={'ml-2'}>{t('trash.text')}</span>
    </div>
  );
}

export default TrashButton;
