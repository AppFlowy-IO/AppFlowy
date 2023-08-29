import { IDatabaseSort } from '$app_reducers/database/slice';
import React, { useEffect, useMemo, useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { DragElementSvg } from '$app/components/_shared/svg/DragElementSvg';
import { SortConditionPB } from '@/services/backend';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { FieldSelect } from '$app/components/_shared/DatabaseFilter/FieldSelect';
import { OrderSelect } from '$app/components/_shared/DatabaseSort/OrderSelect';

export const DatabaseSortItem = ({
  data,
  onSave,
  onDelete,
}: {
  data: IDatabaseSort | null;
  onSave: (sortItem: IDatabaseSort) => void;
  onDelete?: () => void;
}) => {
  // stores
  const columns = useAppSelector((state) => state.database.columns);
  const fields = useAppSelector((state) => state.database.fields);
  const sortStore = useAppSelector((state) => state.database.sort);

  // values
  const [currentFieldId, setCurrentFieldId] = useState<string | null>(data?.fieldId ?? null);
  const [currentOrder, setCurrentOrder] = useState<SortConditionPB | null>(data?.order ?? null);

  const supportedColumns = useMemo(
    () => columns.filter((c) => sortStore.findIndex((s) => s.fieldId === c.fieldId) === -1),
    [columns, sortStore]
  );

  const currentFieldType = useMemo(
    () => (currentFieldId ? fields[currentFieldId].fieldType : undefined),
    [currentFieldId, fields]
  );

  useEffect(() => {
    if (data) {
      setCurrentFieldId(data.fieldId);
      setCurrentOrder(data.order);
    } else {
      setCurrentFieldId(null);
      setCurrentOrder(null);
    }
  }, [data]);

  useEffect(() => {
    if (currentFieldId && currentOrder !== null) {
      onSave({
        id: data?.id,
        fieldId: currentFieldId,
        order: currentOrder,
        fieldType: fields[currentFieldId].fieldType,
      });
    }
  }, [currentFieldId, currentOrder]);

  const onSelectFieldClick = (id: string) => {
    setCurrentFieldId(id);
    // set ascending order by default
    setCurrentOrder(SortConditionPB.Ascending);
  };

  const onSelectOrderClick = (order: SortConditionPB) => {
    setCurrentOrder(order);
  };

  return (
    <div className={'flex items-center gap-4'}>
      <button className={'flex-shrink-0 rounded p-1 hover:bg-fill-list-hover'}>
        <i className={'block h-[16px] w-[16px]'}>
          <DragElementSvg></DragElementSvg>
        </i>
      </button>

      <FieldSelect
        columns={supportedColumns}
        fields={fields}
        onSelectFieldClick={onSelectFieldClick}
        currentFieldId={currentFieldId}
        currentFieldType={currentFieldType}
      ></FieldSelect>

      <OrderSelect currentOrder={currentOrder} onSelectOrderClick={onSelectOrderClick}></OrderSelect>

      <button
        onClick={() => onDelete?.()}
        className={`rounded p-1 hover:bg-fill-list-hover ${data ? 'opacity-100' : 'opacity-0'}`}
      >
        <i className={'block h-[16px] w-[16px]'}>
          <TrashSvg />
        </i>
      </button>
    </div>
  );
};
