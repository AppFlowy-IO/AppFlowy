import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { DateCellDataPB, FieldType, SelectOptionCellDataPB, URLCellDataPB } from '@/services/backend';
import { useAppSelector } from '$app/stores/store';
import { EditCellText } from '$app/components/_shared/EditRow/InlineEditFields/EditCellText';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { EditCellDate } from '$app/components/_shared/EditRow/Date/EditCellDate';
import { useRef } from 'react';
import { CellOptions } from '$app/components/_shared/EditRow/Options/CellOptions';
import { EditCellNumber } from '$app/components/_shared/EditRow/InlineEditFields/EditCellNumber';
import { EditCheckboxCell } from '$app/components/_shared/EditRow/InlineEditFields/EditCheckboxCell';
import { EditCellUrl } from '$app/components/_shared/EditRow/InlineEditFields/EditCellUrl';
import { Draggable } from 'react-beautiful-dnd';
import { DragElementSvg } from '$app/components/_shared/svg/DragElementSvg';
import { CheckList } from '$app/components/_shared/EditRow/CheckList/CheckList';

export const EditCellWrapper = ({
  index,
  cellIdentifier,
  cellCache,
  fieldController,
  onEditFieldClick,
  onEditOptionsClick,
  onEditDateClick,
  onEditCheckListClick,
}: {
  index: number;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onEditFieldClick: (cell: CellIdentifier, left: number, top: number) => void;
  onEditOptionsClick: (cell: CellIdentifier, left: number, top: number) => void;
  onEditDateClick: (cell: CellIdentifier, left: number, top: number) => void;
  onEditCheckListClick: (cell: CellIdentifier, left: number, top: number) => void;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const el = useRef<HTMLDivElement>(null);

  const onClick = () => {
    if (!el.current) return;
    const { top, right } = el.current.getBoundingClientRect();
    onEditFieldClick(cellIdentifier, right, top);
  };

  return (
    <Draggable draggableId={cellIdentifier.fieldId} index={index} key={cellIdentifier.fieldId}>
      {(provided) => (
        <div
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          className={'flex w-full flex-col items-start gap-2 text-xs'}
        >
          <div
            className={
              'relative flex cursor-pointer items-center gap-2 rounded-lg text-white transition-colors duration-200 hover:text-shade-3'
            }
          >
            <div ref={el} onClick={() => onClick()} className={'flex h-5 w-5'}>
              <DragElementSvg></DragElementSvg>
            </div>

            <div className={'flex h-5 w-5 flex-shrink-0 items-center justify-center text-shade-3'}>
              <FieldTypeIcon fieldType={cellIdentifier.fieldType}></FieldTypeIcon>
            </div>
            <span className={'overflow-hidden text-ellipsis whitespace-nowrap text-shade-3'}>
              {databaseStore.fields[cellIdentifier.fieldId]?.title ?? ''}
            </span>
          </div>

          <div className={'w-full cursor-pointer rounded-lg pl-3 text-sm hover:bg-shade-6'}>
            {(cellIdentifier.fieldType === FieldType.SingleSelect ||
              cellIdentifier.fieldType === FieldType.MultiSelect) &&
              cellController && (
                <CellOptions
                  data={data as SelectOptionCellDataPB}
                  onEditClick={(left, top) => onEditOptionsClick(cellIdentifier, left, top)}
                ></CellOptions>
              )}

            {cellIdentifier.fieldType === FieldType.Checklist && cellController && (
              <CheckList
                data={data as SelectOptionCellDataPB}
                fieldId={cellIdentifier.fieldId}
                onEditClick={(left, top) => onEditCheckListClick(cellIdentifier, left, top)}
              ></CheckList>
            )}

            {cellIdentifier.fieldType === FieldType.Checkbox && cellController && (
              <EditCheckboxCell
                data={data as 'Yes' | 'No' | undefined}
                cellController={cellController}
              ></EditCheckboxCell>
            )}

            {cellIdentifier.fieldType === FieldType.DateTime && (
              <EditCellDate
                data={data as DateCellDataPB}
                onEditClick={(left, top) => onEditDateClick(cellIdentifier, left, top)}
              ></EditCellDate>
            )}

            {cellIdentifier.fieldType === FieldType.Number && cellController && (
              <EditCellNumber data={data as string | undefined} cellController={cellController}></EditCellNumber>
            )}

            {cellIdentifier.fieldType === FieldType.URL && cellController && (
              <EditCellUrl data={data as URLCellDataPB} cellController={cellController}></EditCellUrl>
            )}

            {cellIdentifier.fieldType === FieldType.RichText && cellController && (
              <EditCellText data={data as string | undefined} cellController={cellController}></EditCellText>
            )}
          </div>
        </div>
      )}
    </Draggable>
  );
};
