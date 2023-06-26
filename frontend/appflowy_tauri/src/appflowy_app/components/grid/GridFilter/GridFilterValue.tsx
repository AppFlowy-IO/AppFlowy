import { DateCellDataPB, FieldType, SelectOptionCellDataPB, URLCellDataPB } from '@/services/backend';
import { CheckList } from '../../_shared/EditRow/CheckList/CheckList';
import { EditCellDate } from '../../_shared/EditRow/Date/EditCellDate';
import { EditCellNumber } from '../../_shared/EditRow/InlineEditFields/EditCellNumber';
import { EditCellText } from '../../_shared/EditRow/InlineEditFields/EditCellText';
import { EditCellUrl } from '../../_shared/EditRow/InlineEditFields/EditCellUrl';
import { EditCheckboxCell } from '../../_shared/EditRow/InlineEditFields/EditCheckboxCell';
import { CellOptions } from '../../_shared/EditRow/Options/CellOptions';

export const GridFilterValue = ({
  fieldType,
  fieldId,
  value,
}: {
  fieldType: FieldType;
  fieldId: string;
  value: any;
}) => {
  return (
    <div className={'w-full cursor-pointer rounded-lg  text-sm hover:bg-shade-6'}>
      {(fieldType === FieldType.SingleSelect || fieldType === FieldType.MultiSelect) && (
        <CellOptions
          data={value as SelectOptionCellDataPB}
          // onEditClick={(left, top) => onEditOptionsClick(cellIdentifier, left, top)}
          onEditClick={(left, top) => {
            console.log('onEditClick');
          }}
        ></CellOptions>
      )}

      {fieldType === FieldType.Checklist && (
        <CheckList
          data={value as SelectOptionCellDataPB}
          fieldId={fieldId}
          // onEditClick={(left, top) => onEditCheckListClick(cellIdentifier, left, top)}
          onEditClick={(left, top) => {
            console.log('onEditClick');
          }}
        ></CheckList>
      )}

      {fieldType === FieldType.Checkbox && (
        <EditCheckboxCell
          data={value as 'Yes' | 'No' | undefined}
          onToggle={async () => {
            if (value === 'Yes') {
              console.log("data is 'Yes'");
            } else {
              console.log("data is 'No'");
            }
          }}
        ></EditCheckboxCell>
      )}

      {fieldType === FieldType.DateTime && (
        <EditCellDate
          data={value as DateCellDataPB}
          // onEditClick={(left, top) => onEditDateClick(cellIdentifier, left, top)}
          onEditClick={(left, top) => {
            console.log('onEditClick');
          }}
        ></EditCellDate>
      )}

      {fieldType === FieldType.Number && (
        <EditCellNumber
          data={value as string | undefined}
          onSave={async (data) => {
            console.log({ data });
          }}
        ></EditCellNumber>
      )}

      {fieldType === FieldType.URL && (
        <EditCellUrl
          data={value as URLCellDataPB}
          onSave={async (data) => {
            console.log({ data });
          }}
        ></EditCellUrl>
      )}

      {fieldType === FieldType.RichText && (
        <EditCellText
          data={value as string | undefined}
          onSave={async (data) => {
            console.log({ data });
          }}
        ></EditCellText>
      )}
    </div>
  );
};
