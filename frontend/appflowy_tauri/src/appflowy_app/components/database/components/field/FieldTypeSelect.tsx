import React, { useRef, useState } from 'react';
import { FieldTypeSvg } from '$app/components/database/components/field/FieldTypeSvg';
import { FieldTypeText } from '$app/components/database/components/field/FieldTypeText';
import { MenuItem } from '@mui/material';
import { Field } from '$app/components/database/application';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { FieldTypeMenu } from '$app/components/database/components/field/FieldTypeMenu';
import { FieldType } from '@/services/backend';

interface Props {
  field: Field;
  onUpdateFieldType: (type: FieldType) => void;
}
function FieldTypeSelect({ field, onUpdateFieldType }: Props) {
  const [expanded, setExpanded] = useState(false);
  const ref = useRef<HTMLLIElement>(null);

  return (
    <>
      <MenuItem
        ref={ref}
        onClick={() => {
          setExpanded(!expanded);
        }}
        dense
      >
        <FieldTypeSvg type={field.type} className='mr-2 text-base' />
        <span className='flex-1 text-xs font-medium'>
          <FieldTypeText type={field.type} />
        </span>
        <MoreSvg className={`transform text-base ${expanded ? '' : 'rotate-90'}`} />
      </MenuItem>
      {expanded && (
        <FieldTypeMenu
          keepMounted={false}
          field={field}
          onClickItem={onUpdateFieldType}
          open={expanded}
          anchorEl={ref.current}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'left',
          }}
          anchorOrigin={{
            vertical: 'top',
            horizontal: 'right',
          }}
          onClose={() => {
            setExpanded(false);
          }}
        />
      )}
    </>
  );
}

export default FieldTypeSelect;
