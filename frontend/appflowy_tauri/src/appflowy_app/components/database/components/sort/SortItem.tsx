import { IconButton, SelectChangeEvent, Stack } from '@mui/material';
import { FC, useCallback } from 'react';
import { ReactComponent as CloseSvg } from '$app/assets/close.svg';
import { Field, Sort, sortService } from '../../application';
import { PropertySelect } from '../property';
import { SortConditionSelect } from './SortConditionSelect';
import { useViewId } from '@/appflowy_app/hooks';
import { SortConditionPB } from '@/services/backend';

export interface SortItemProps {
  className?: string;
  sort: Sort;
}

export const SortItem: FC<SortItemProps> = ({ className, sort }) => {
  const viewId = useViewId();

  const handleFieldChange = useCallback(
    (field: Field | undefined) => {
      if (field) {
        void sortService.updateSort(viewId, {
          ...sort,
          fieldId: field.id,
          fieldType: field.type,
        });
      }
    },
    [viewId, sort]
  );

  const handleConditionChange = useCallback(
    (event: SelectChangeEvent<SortConditionPB>) => {
      void sortService.updateSort(viewId, {
        ...sort,
        condition: event.target.value as SortConditionPB,
      });
    },
    [viewId, sort]
  );

  const handleClick = useCallback(() => {
    void sortService.deleteSort(viewId, sort);
  }, [viewId, sort]);

  return (
    <Stack className={className} direction='row' spacing={1}>
      <PropertySelect className={'w-[150px]'} size='small' value={sort.fieldId} onChange={handleFieldChange} />
      <SortConditionSelect
        className={'w-[150px]'}
        size='small'
        value={sort.condition}
        onChange={handleConditionChange}
      />
      <div className={'flex items-center justify-center'}>
        <IconButton size={'small'} onClick={handleClick}>
          <CloseSvg />
        </IconButton>
      </div>
    </Stack>
  );
};
