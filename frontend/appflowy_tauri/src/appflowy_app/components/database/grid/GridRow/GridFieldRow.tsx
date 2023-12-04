import { useDatabaseVisibilityFields } from '../../Database.hooks';
import { GridField } from '../GridField';
import { DEFAULT_FIELD_WIDTH } from '$app/components/database/grid/GridRow/constants';
import React, { useCallback, useState } from 'react';
import NewProperty from '$app/components/database/components/property/NewProperty';

export const GridFieldRow = () => {
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);
  const fields = useDatabaseVisibilityFields();

  const handleOpenMenu = useCallback((id: string) => {
    setOpenMenuId(id);
  }, []);

  const handleCloseMenu = useCallback((id: string) => {
    setOpenMenuId((prev) => {
      if (prev === id) {
        return null;
      }

      return prev;
    });
  }, []);

  return (
    <>
      <div className='z-10 flex border-b border-line-divider '>
        <div className={'flex '}>
          {fields.map((field) => {
            return (
              <GridField
                onCloseMenu={handleCloseMenu}
                onOpenMenu={handleOpenMenu}
                menuOpened={openMenuId === field.id}
                key={field.id}
                field={field}
              />
            );
          })}
        </div>

        <div className={` w-[${DEFAULT_FIELD_WIDTH}px]`}>
          <NewProperty onInserted={setOpenMenuId} />
        </div>
      </div>
    </>
  );
};
