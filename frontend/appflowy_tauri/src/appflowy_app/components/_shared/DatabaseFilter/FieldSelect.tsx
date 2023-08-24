import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import ButtonPopoverList from '$app/components/_shared/ButtonPopoverList';
import React, { useState } from 'react';
import { DatabaseFieldMap, IDatabaseColumn } from '$app_reducers/database/slice';
import { FieldType } from '@/services/backend';

interface IFieldSelectProps {
  columns: IDatabaseColumn[];
  fields: DatabaseFieldMap;
  onSelectFieldClick: (fieldId: string) => void;
  currentFieldId: string | null;
  currentFieldType: FieldType | undefined;
}

const WIDTH = 180;

export const FieldSelect = ({
  columns,
  fields,
  onSelectFieldClick,
  currentFieldId,
  currentFieldType,
}: IFieldSelectProps) => {
  const [showSelect, setShowSelect] = useState(false);

  return (
    <ButtonPopoverList
      isVisible={true}
      popoverOptions={columns.map((column) => ({
        key: column.fieldId,
        icon: (
          <i className={'block h-5 w-5'}>
            <FieldTypeIcon fieldType={fields[column.fieldId].fieldType}></FieldTypeIcon>
          </i>
        ),
        label: fields[column.fieldId].title,
        onClick: () => {
          onSelectFieldClick(column.fieldId);
          setShowSelect(false);
        },
      }))}
      popoverOrigin={{
        anchorOrigin: {
          vertical: 'bottom',
          horizontal: 'left',
        },
        transformOrigin: {
          vertical: 'top',
          horizontal: 'left',
        },
      }}
      onClose={() => setShowSelect(false)}
      sx={{ width: `${WIDTH}px` }}
    >
      <div
        onClick={() => setShowSelect(true)}
        className={`flex items-center justify-between rounded-lg border px-2 py-1 ${
          showSelect ? 'border-fill-hover' : 'border-line-border'
        }`}
        style={{ width: `${WIDTH}px` }}
      >
        {currentFieldType !== undefined && currentFieldId ? (
          <div className={'flex items-center gap-2'}>
            <i className={'block h-5 w-5'}>
              <FieldTypeIcon fieldType={currentFieldType}></FieldTypeIcon>
            </i>
            <span>{fields[currentFieldId].title}</span>
          </div>
        ) : (
          <span className={'text-text-placeholder'}>Select a field</span>
        )}
        <i className={`h-5 w-5 transition-transform duration-500 ${showSelect ? 'rotate-180' : 'rotate-0'}`}>
          <DropDownShowSvg></DropDownShowSvg>
        </i>
      </div>
    </ButtonPopoverList>
  );
};
