import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { DateCellDataPB, FieldType, SelectOptionCellDataPB } from '@/services/backend';
import { useAppSelector } from '$app/stores/store';
import { getBgColor } from '$app/components/_shared/getColor';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { EditCellText } from '$app/components/_shared/EditRow/EditCellText';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { EditCellDate } from '$app/components/_shared/EditRow/EditCellDate';
import { useRef } from 'react';
import { CellOptions } from '$app/components/_shared/EditRow/CellOptions';

export const EditCellWrapper = ({
  cellIdentifier,
  cellCache,
  fieldController,
  onEditFieldClick,
  onEditOptionsClick,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onEditFieldClick: (top: number, right: number) => void;
  onEditOptionsClick: (left: number, top: number) => void;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const el = useRef<HTMLDivElement>(null);

  const onClick = () => {
    if (!el.current) return;
    const { top, right } = el.current.getBoundingClientRect();
    onEditFieldClick(top, right);
  };

  return (
    <div className={'flex w-full items-center text-xs'}>
      <div
        ref={el}
        onClick={() => onClick()}
        className={'relative flex w-[180px] cursor-pointer items-center gap-2 rounded-lg px-3 py-1.5 hover:bg-shade-6'}
      >
        <div className={'flex h-5 w-5 flex-shrink-0 items-center justify-center'}>
          <FieldTypeIcon fieldType={cellIdentifier.fieldType}></FieldTypeIcon>
        </div>
        <span className={'overflow-hidden text-ellipsis whitespace-nowrap'}>
          {databaseStore.fields[cellIdentifier.fieldId].title}
        </span>
      </div>
      <div className={'flex-1 cursor-pointer rounded-lg hover:bg-shade-6'}>
        {(cellIdentifier.fieldType === FieldType.SingleSelect ||
          cellIdentifier.fieldType === FieldType.MultiSelect ||
          cellIdentifier.fieldType === FieldType.Checklist) &&
          cellController && (
            <CellOptions
              data={data as SelectOptionCellDataPB | undefined}
              onEditClick={onEditOptionsClick}
            ></CellOptions>
          )}

        {cellIdentifier.fieldType === FieldType.Checkbox && (
          <div className={'h-8 w-8 px-4 py-2'}>
            {(data as boolean | undefined) ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
          </div>
        )}

        {cellIdentifier.fieldType === FieldType.DateTime && cellController && (
          <EditCellDate data={data as DateCellDataPB | undefined} cellController={cellController}></EditCellDate>
        )}

        {(cellIdentifier.fieldType === FieldType.RichText ||
          cellIdentifier.fieldType === FieldType.URL ||
          cellIdentifier.fieldType === FieldType.Number) &&
          cellController && <EditCellText data={data as string} cellController={cellController}></EditCellText>}
      </div>
    </div>
  );
};
