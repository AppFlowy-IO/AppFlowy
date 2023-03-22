import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { DateCellDataPB, FieldType, SelectOptionCellDataPB } from '@/services/backend';
import { useAppSelector } from '$app/stores/store';
import { getBgColor } from '$app/components/_shared/getColor';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { useState } from 'react';
import { EditCellText } from '$app/components/board/EditBoardRow/EditCellText';
import { EditFieldPopup } from '$app/components/board/EditBoardRow/EditFieldPopup';
import { FieldTypeIcon } from '$app/components/board/EditBoardRow/FieldTypeIcon';

export const EditCellWrapper = ({
  viewId,
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  viewId: string;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const [showFieldEditor, setShowFieldEditor] = useState(false);
  const onEditFieldClick = () => {
    setShowFieldEditor(true);
  };

  return (
    <div className={'flex w-full items-center text-xs'}>
      <div
        onClick={() => onEditFieldClick()}
        className={'relative flex w-[180px] cursor-pointer items-center gap-2 rounded-lg px-3 py-1.5 hover:bg-shade-6'}
      >
        <div className={'flex h-5 w-5 flex-shrink-0 items-center justify-center'}>
          <FieldTypeIcon fieldType={cellIdentifier.fieldType}></FieldTypeIcon>
        </div>
        <span className={'overflow-hidden text-ellipsis whitespace-nowrap'}>
          {databaseStore.fields[cellIdentifier.fieldId].title}
        </span>
        {showFieldEditor && cellController && (
          <EditFieldPopup
            fieldName={databaseStore.fields[cellIdentifier.fieldId].title}
            fieldType={cellIdentifier.fieldType}
            viewId={viewId}
            cellController={cellController}
            onOutsideClick={() => setShowFieldEditor(false)}
            fieldInfo={fieldController.getField(cellIdentifier.fieldId)}
          ></EditFieldPopup>
        )}
      </div>
      <div className={'flex-1 cursor-pointer rounded-lg px-4 py-2 hover:bg-shade-6'}>
        {(cellIdentifier.fieldType === FieldType.SingleSelect ||
          cellIdentifier.fieldType === FieldType.MultiSelect ||
          cellIdentifier.fieldType === FieldType.Checklist) && (
          <div className={'flex items-center gap-2'}>
            {(data as SelectOptionCellDataPB | undefined)?.select_options?.map((option, index) => (
              <div className={`${getBgColor(option.color)} rounded px-2 py-0.5`} key={index}>
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
