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
  onEditFieldClick: (cell: CellIdentifier, anchorEl: HTMLDivElement) => void;
  onEditOptionsClick: (cell: CellIdentifier, left: number, top: number) => void;
  onEditDateClick: (cell: CellIdentifier, left: number, top: number) => void;
  onEditCheckListClick: (cell: CellIdentifier, left: number, top: number) => void;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const el = useRef<HTMLDivElement>(null);

  const onClick = () => {
    if (!el.current) return;

    onEditFieldClick(cellIdentifier, el.current);
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
          <div className={'relative flex cursor-pointer items-center gap-2 rounded-lg transition-colors duration-200'}>
            <div
              ref={el}
              onClick={() => onClick()}
              className={'text-icon-default flex h-5 w-5 rounded hover:bg-fill-list-hover'}
            >
              <DragElementSvg></DragElementSvg>
            </div>

            <div className={'flex h-5 w-5 flex-shrink-0 items-center justify-center text-text-caption'}>
              <FieldTypeIcon fieldType={cellIdentifier.fieldType}></FieldTypeIcon>
            </div>
            <span className={'overflow-hidden text-ellipsis whitespace-nowrap text-text-caption'}>
              {databaseStore.fields[cellIdentifier.fieldId]?.title ?? ''}
            </span>
          </div>

          <div className={'w-full cursor-pointer rounded-lg pl-3 text-sm hover:bg-content-blue-50'}>
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
                onToggle={async () => {
                  if (data === 'Yes') {
                    await cellController?.saveCellData('No');
                  } else {
                    await cellController?.saveCellData('Yes');
                  }
                }}
              ></EditCheckboxCell>
            )}

            {cellIdentifier.fieldType === FieldType.DateTime && (
              <EditCellDate
                data={data as DateCellDataPB}
                onEditClick={(left, top) => onEditDateClick(cellIdentifier, left, top)}
              ></EditCellDate>
            )}

            {cellIdentifier.fieldType === FieldType.Number && cellController && (
              <EditCellNumber
                data={data as string | undefined}
                onSave={async (value) => {
                  await cellController?.saveCellData(value);
                }}
              ></EditCellNumber>
            )}

            {cellIdentifier.fieldType === FieldType.URL && cellController && (
              <EditCellUrl
                data={data as URLCellDataPB}
                onSave={async (value) => {
                  await cellController?.saveCellData(value);
                }}
              ></EditCellUrl>
            )}

            {cellIdentifier.fieldType === FieldType.RichText && cellController && (
              <EditCellText
                data={data as string | undefined}
                onSave={async (value) => {
                  await cellController?.saveCellData(value);
                }}
              ></EditCellText>
            )}
          </div>
        </div>
      )}
    </Draggable>
  );
};
