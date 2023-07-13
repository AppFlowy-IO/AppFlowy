import { IDatabaseSort, SupportedOperatorsByType } from '$app_reducers/database/slice';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { MouseEventHandler, useEffect, useMemo, useRef, useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { IPopupItem, PopupSelect } from '$app/components/_shared/PopupSelect';
import { DragElementSvg } from '$app/components/_shared/svg/DragElementSvg';
import { FieldType } from '@/services/backend';
import { SortAscSvg } from '$app/components/_shared/svg/SortAscSvg';
import { SortDescSvg } from '$app/components/_shared/svg/SortDescSvg';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';

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
  const [currentOrder, setCurrentOrder] = useState<'asc' | 'desc' | null>(data?.sort ?? null);

  // ui
  const [showFieldSelect, setShowFieldSelect] = useState(false);
  const refFieldSelect = useRef<HTMLDivElement>(null);
  const [fieldSelectTop, setFieldSelectTop] = useState(0);
  const [fieldSelectLeft, setFieldSelectLeft] = useState(0);

  const [showOrderSelect, setShowOrderSelect] = useState(false);
  const refOrderSelect = useRef<HTMLDivElement>(null);
  const [orderSelectTop, setOrderSelectTop] = useState(0);
  const [orderSelectLeft, setOrderSelectLeft] = useState(0);

  const supportedColumns = useMemo(
    () => columns.filter((c) => sortStore.findIndex((s) => s.fieldId === c.fieldId) === -1),
    [columns, sortStore]
  );

  useEffect(() => {
    if (data) {
      setCurrentFieldId(data.fieldId);
      setCurrentOrder(data.sort);
    } else {
      setCurrentFieldId(null);
      setCurrentOrder(null);
    }
  }, [data]);

  useEffect(() => {
    if (currentFieldId && currentOrder) {
      onSave({ fieldId: currentFieldId, sort: currentOrder });
    }
  }, [currentFieldId, currentOrder]);

  const onSelectFieldClick = (id: string) => {
    setCurrentFieldId(id);
    setShowFieldSelect(false);
  };

  const onFieldClick: MouseEventHandler = () => {
    if (!refFieldSelect.current) return;
    const { top, left, height } = refFieldSelect.current.getBoundingClientRect();

    setFieldSelectTop(top + height);
    setFieldSelectLeft(left);
    setShowFieldSelect(true);
  };

  const onSelectOrderClick = (order: 'asc' | 'desc') => {
    setCurrentOrder(order);
    setShowOrderSelect(false);
  };

  const onOrderClick: MouseEventHandler = () => {
    if (!refOrderSelect.current) return;
    const { top, left, height } = refOrderSelect.current.getBoundingClientRect();

    setOrderSelectTop(top + height);
    setOrderSelectLeft(left);
    setShowOrderSelect(true);
  };

  return (
    <>
      <div className={'flex items-center gap-2'}>
        <button className={'flex-shrink-0 rounded p-1 hover:bg-main-secondary'}>
          <i className={'block h-[16px] w-[16px]'}>
            <DragElementSvg></DragElementSvg>
          </i>
        </button>
        <div className={'flex flex-1 items-center gap-2'}>
          <div
            className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
              showFieldSelect ? 'border-main-accent' : 'border-shade-4'
            }`}
            ref={refFieldSelect}
            onClick={onFieldClick}
          >
            {currentFieldId ? (
              <div className={'flex items-center gap-2'}>
                <i className={'block h-5 w-5'}>
                  <FieldTypeIcon fieldType={fields[currentFieldId].fieldType}></FieldTypeIcon>
                </i>
                <span>{fields[currentFieldId].title}</span>
              </div>
            ) : (
              <span className={'text-shade-4'}>Select a field</span>
            )}
          </div>
          <div
            className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
              showOrderSelect ? 'border-main-accent' : 'border-shade-4'
            }`}
            ref={refOrderSelect}
            onClick={onOrderClick}
          >
            {currentOrder ? (
              <SortLabel value={currentOrder}></SortLabel>
            ) : (
              <span className={'text-shade-4'}>Select order</span>
            )}
          </div>
        </div>
        <button
          onClick={() => onDelete?.()}
          className={`rounded p-1 hover:bg-main-secondary ${data ? 'opacity-100' : 'opacity-0'}`}
        >
          <i className={'block h-[16px] w-[16px]'}>
            <TrashSvg />
          </i>
        </button>
      </div>
      {showFieldSelect && (
        <PopupSelect
          items={supportedColumns.map<IPopupItem>((c) => ({
            icon: (
              <i className={'block h-5 w-5'}>
                <FieldTypeIcon fieldType={fields[c.fieldId].fieldType}></FieldTypeIcon>
              </i>
            ),
            title: fields[c.fieldId].title,
            onClick: () => onSelectFieldClick(c.fieldId),
          }))}
          className={'fixed z-10 text-sm'}
          style={{ top: `${fieldSelectTop}px`, left: `${fieldSelectLeft}px`, width: `${180}px` }}
          onOutsideClick={() => setShowFieldSelect(false)}
        ></PopupSelect>
      )}
      {showOrderSelect && (
        <PopupSelect
          items={[
            {
              icon: (
                <i className={'h-5 w-5'}>
                  <SortAscSvg></SortAscSvg>
                </i>
              ),
              title: 'Ascending',
              onClick: () => onSelectOrderClick('asc'),
            },
            {
              icon: (
                <i className={'h-5 w-5'}>
                  <SortDescSvg></SortDescSvg>
                </i>
              ),
              title: 'Descending',
              onClick: () => onSelectOrderClick('desc'),
            },
          ]}
          className={'fixed z-10 text-sm'}
          style={{ top: `${orderSelectTop}px`, left: `${orderSelectLeft}px`, width: `${180}px` }}
          onOutsideClick={() => setShowOrderSelect(false)}
        ></PopupSelect>
      )}
    </>
  );
};

const SortLabel = ({ value }: { value: 'asc' | 'desc' }) => {
  return value === 'asc' ? (
    <div className={'flex items-center gap-2'}>
      <i className={'block h-5 w-5'}>
        <SortAscSvg></SortAscSvg>
      </i>
      <span>Ascending</span>
    </div>
  ) : (
    <div className={'flex items-center gap-2'}>
      <i className={'block h-5 w-5'}>
        <SortDescSvg></SortDescSvg>
      </i>
      <span>Descending</span>
    </div>
  );
};
