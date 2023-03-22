import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { DateCellDataPB, FieldType, SelectOptionCellDataPB } from '@/services/backend';
import { TextTypeSvg } from '$app/components/_shared/svg/TextTypeSvg';
import { NumberTypeSvg } from '$app/components/_shared/svg/NumberTypeSvg';
import { DateTypeSvg } from '$app/components/_shared/svg/DateTypeSvg';
import { SingleSelectTypeSvg } from '$app/components/_shared/svg/SingleSelectTypeSvg';
import { MultiSelectTypeSvg } from '$app/components/_shared/svg/MultiSelectTypeSvg';
import { ChecklistTypeSvg } from '$app/components/_shared/svg/ChecklistTypeSvg';
import { UrlTypeSvg } from '$app/components/_shared/svg/UrlTypeSvg';
import { useAppSelector } from '$app/stores/store';
import { getBgColor } from '$app/components/_shared/getColor';
import { CheckboxSvg } from '$app/components/_shared/svg/CheckboxSvg';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { useState } from 'react';
import { EditCellText } from '$app/components/board/EditBoardRow/EditCellText';

export const EditCellWrapper = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const [showEditField, setShowEditField] = useState(false);
  const onEditFieldClick = () => {
    setShowEditField(true);
  };

  return (
    <div className={'flex w-full items-center'}>
      <div
        onClick={() => onEditFieldClick()}
        className={'flex w-[180px] cursor-pointer items-center gap-2 rounded-lg px-4 py-2 hover:bg-shade-6'}
      >
        <div className={'h-5 w-5 flex-shrink-0'}>
          {cellIdentifier.fieldType === FieldType.RichText && <TextTypeSvg></TextTypeSvg>}
          {cellIdentifier.fieldType === FieldType.Number && <NumberTypeSvg></NumberTypeSvg>}
          {cellIdentifier.fieldType === FieldType.DateTime && <DateTypeSvg></DateTypeSvg>}
          {cellIdentifier.fieldType === FieldType.SingleSelect && <SingleSelectTypeSvg></SingleSelectTypeSvg>}
          {cellIdentifier.fieldType === FieldType.MultiSelect && <MultiSelectTypeSvg></MultiSelectTypeSvg>}
          {cellIdentifier.fieldType === FieldType.Checklist && <ChecklistTypeSvg></ChecklistTypeSvg>}
          {cellIdentifier.fieldType === FieldType.URL && <UrlTypeSvg></UrlTypeSvg>}
          {cellIdentifier.fieldType === FieldType.Checkbox && <CheckboxSvg></CheckboxSvg>}
        </div>
        <span className={'overflow-hidden text-ellipsis whitespace-nowrap'}>
          {databaseStore.fields[cellIdentifier.fieldId].title}
        </span>
      </div>
      <div className={'flex-1 cursor-pointer rounded-lg px-4 py-2 hover:bg-shade-6'}>
        {(cellIdentifier.fieldType === FieldType.SingleSelect ||
          cellIdentifier.fieldType === FieldType.MultiSelect ||
          cellIdentifier.fieldType === FieldType.Checklist) && (
          <div className={'flex items-center gap-2'}>
            {(data as SelectOptionCellDataPB | undefined)?.select_options?.map((option, index) => (
              <div className={`${getBgColor(option.color)} rounded px-2 py-0.5 text-xs`} key={index}>
                {option?.name || ''}
              </div>
            )) || ''}
          </div>
        )}

        {cellIdentifier.fieldType === FieldType.Checkbox && (
          <div className={'h-8 w-8'}>
            {(data as boolean | undefined) ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
          </div>
        )}

        {cellIdentifier.fieldType === FieldType.DateTime && <div>{(data as DateCellDataPB | undefined)?.date}</div>}

        {(cellIdentifier.fieldType === FieldType.RichText ||
          cellIdentifier.fieldType === FieldType.URL ||
          cellIdentifier.fieldType === FieldType.Number) &&
          cellController && <EditCellText data={data as string} cellController={cellController}></EditCellText>}
      </div>
    </div>
  );
};
