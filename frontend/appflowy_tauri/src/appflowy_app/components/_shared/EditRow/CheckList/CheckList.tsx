import { SelectOptionCellDataPB } from '@/services/backend';
import { useEffect, useRef, useState } from 'react';
import { ISelectOptionType } from '$app_reducers/database/slice';
import { useAppSelector } from '$app/stores/store';
import { CheckListProgress } from '$app/components/_shared/CheckListProgress';

export const CheckList = ({
  data,
  fieldId,
  onEditClick,
}: {
  data: SelectOptionCellDataPB | undefined;
  fieldId: string;
  onEditClick: (left: number, top: number) => void;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const [allOptionsCount, setAllOptionsCount] = useState(0);
  const [selectedOptionsCount, setSelectedOptionsCount] = useState(0);
  const databaseStore = useAppSelector((state) => state.database);

  useEffect(() => {
    setAllOptionsCount((databaseStore.fields[fieldId]?.fieldOptions as ISelectOptionType)?.selectOptions?.length ?? 0);
  }, [databaseStore, fieldId]);

  useEffect(() => {
    setSelectedOptionsCount((data as SelectOptionCellDataPB)?.select_options?.length ?? 0);
  }, [data]);

  const onClick = () => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    onEditClick(left, top);
  };

  return (
    <div ref={ref} onClick={onClick} className={'flex w-full flex-wrap items-center gap-2 px-4 py-1 text-xs text-black'}>
      <CheckListProgress completed={selectedOptionsCount} max={allOptionsCount} />
    </div>
  );
};
