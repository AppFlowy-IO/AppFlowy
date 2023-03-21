import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { FieldType, SelectOptionCellDataPB } from '@/services/backend';
import { TextTypeSvg } from '$app/components/_shared/svg/TextTypeSvg';
import { NumberTypeSvg } from '$app/components/_shared/svg/NumberTypeSvg';
import { DateTypeSvg } from '$app/components/_shared/svg/DateTypeSvg';
import { SingleSelectTypeSvg } from '$app/components/_shared/svg/SingleSelectTypeSvg';
import { MultiSelectTypeSvg } from '$app/components/_shared/svg/MultiSelectTypeSvg';
import { ChecklistTypeSvg } from '$app/components/_shared/svg/ChecklistTypeSvg';
import { UrlTypeSvg } from '$app/components/_shared/svg/UrlTypeSvg';
import { useAppSelector } from '$app/stores/store';

export const EditBoardCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data } = useCell(cellIdentifier, cellCache, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  return (
    <div className={'flex w-full items-center'}>
      <div className={'flex w-[180px] cursor-pointer items-center gap-2 rounded-lg px-4 py-2 hover:bg-shade-6'}>
        <div className={'h-5 w-5 flex-shrink-0'}>
          {cellIdentifier.fieldType === FieldType.RichText && <TextTypeSvg></TextTypeSvg>}
          {cellIdentifier.fieldType === FieldType.Number && <NumberTypeSvg></NumberTypeSvg>}
          {cellIdentifier.fieldType === FieldType.DateTime && <DateTypeSvg></DateTypeSvg>}
          {cellIdentifier.fieldType === FieldType.SingleSelect && <SingleSelectTypeSvg></SingleSelectTypeSvg>}
          {cellIdentifier.fieldType === FieldType.MultiSelect && <MultiSelectTypeSvg></MultiSelectTypeSvg>}
          {cellIdentifier.fieldType === FieldType.Checklist && <ChecklistTypeSvg></ChecklistTypeSvg>}
          {cellIdentifier.fieldType === FieldType.URL && <UrlTypeSvg></UrlTypeSvg>}
        </div>
        <span className={'overflow-hidden text-ellipsis whitespace-nowrap'}>
          {databaseStore.fields[cellIdentifier.fieldId].title}
        </span>
      </div>
      <div className={'flex-1'}>
        {(cellIdentifier.fieldType === FieldType.SingleSelect || cellIdentifier.fieldType === FieldType.MultiSelect) && (
          <div>
            {(data as SelectOptionCellDataPB | undefined)?.select_options?.map((option, index) => (
              <div key={index}>{option?.name || ''}</div>
            )) || ''}
          </div>
        )}
        {<div>{data as string}</div>}
      </div>
    </div>
  );
};
