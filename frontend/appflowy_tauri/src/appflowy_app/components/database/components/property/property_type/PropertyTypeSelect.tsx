import React, { useRef, useState } from 'react';
import { ProppertyTypeSvg } from '$app/components/database/components/property/property_type/ProppertyTypeSvg';
import { MenuItem } from '@mui/material';
import { Field } from '$app/components/database/application';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { PropertyTypeMenu } from '$app/components/database/components/property/property_type/PropertyTypeMenu';
import { FieldType } from '@/services/backend';
import { PropertyTypeText } from '$app/components/database/components/property/property_type/PropertyTypeText';

interface Props {
  field: Field;
  onUpdateFieldType: (type: FieldType) => void;
}
function PropertyTypeSelect({ field, onUpdateFieldType }: Props) {
  const [expanded, setExpanded] = useState(false);
  const ref = useRef<HTMLLIElement>(null);

  return (
    <div className={'px-1'}>
      <MenuItem
        ref={ref}
        onClick={() => {
          setExpanded(!expanded);
        }}
        className={'px-23 mx-0'}
      >
        <ProppertyTypeSvg type={field.type} className='mr-2 text-base' />
        <span className='flex-1 text-xs font-medium'>
          <PropertyTypeText type={field.type} />
        </span>
        <MoreSvg className={`transform text-base ${expanded ? '' : 'rotate-90'}`} />
      </MenuItem>
      {expanded && (
        <PropertyTypeMenu
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
    </div>
  );
}

export default PropertyTypeSelect;
