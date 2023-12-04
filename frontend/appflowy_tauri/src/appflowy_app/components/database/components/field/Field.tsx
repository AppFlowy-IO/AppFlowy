import { FC } from 'react';
import { Field as FieldType } from '../../application';
import { FieldTypeSvg } from './FieldTypeSvg';

export interface FieldProps {
  field: FieldType;
}

export const Field: FC<FieldProps> = ({ field }) => {
  return (
    <div className='flex w-full items-center px-2'>
      <FieldTypeSvg className='mr-1 text-base' type={field.type} />
      <span className='flex-1 truncate text-left text-xs'>{field.name}</span>
    </div>
  );
};
