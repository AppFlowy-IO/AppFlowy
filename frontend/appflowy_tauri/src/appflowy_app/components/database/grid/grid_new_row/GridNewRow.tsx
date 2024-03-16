import React, { useCallback } from 'react';
import { rowService } from '$app/application/database';
import { useViewId } from '$app/hooks';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';

interface Props {
  index: number;
  groupId?: string;
  getContainerRef?: () => React.RefObject<HTMLDivElement>;
}

const CSS_HIGHLIGHT_PROPERTY = 'bg-content-blue-50';

function GridNewRow({ index, groupId, getContainerRef }: Props) {
  const viewId = useViewId();

  const { t } = useTranslation();
  const handleClick = useCallback(() => {
    void rowService.createRow(viewId, {
      groupId,
    });
  }, [viewId, groupId]);

  const toggleCssProperty = useCallback(
    (status: boolean) => {
      const container = getContainerRef?.()?.current;

      if (!container) return;

      const newRowCells = container.querySelectorAll('.grid-new-row');

      newRowCells.forEach((cell) => {
        if (status) {
          cell.classList.add(CSS_HIGHLIGHT_PROPERTY);
        } else {
          cell.classList.remove(CSS_HIGHLIGHT_PROPERTY);
        }
      });
    },
    [getContainerRef]
  );

  return (
    <div
      onMouseEnter={() => {
        toggleCssProperty(true);
      }}
      onMouseLeave={() => {
        toggleCssProperty(false);
      }}
      onClick={handleClick}
      className={'grid-new-row flex grow cursor-pointer text-text-title'}
    >
      <span
        style={{
          visibility: index === 1 ? 'visible' : 'hidden',
        }}
        className='sticky left-2 inline-flex items-center'
      >
        <AddSvg className='mr-1 text-base' />
        {t('grid.row.newRow')}
      </span>
    </div>
  );
}

export default GridNewRow;
