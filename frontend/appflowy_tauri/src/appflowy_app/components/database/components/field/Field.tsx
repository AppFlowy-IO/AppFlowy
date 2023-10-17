import { FC } from 'react';
import { Field as FieldType } from '../../application';
import { FieldTypeSvg } from './FieldTypeSvg';

export interface FieldProps {
  field: FieldType;
}

export const Field: FC<FieldProps> = ({
  field,
}) => {
  return (
    <div className="flex items-center px-2 w-full">
      <FieldTypeSvg className="text-base mr-1" type={field.type} />
      <span className="flex-1 text-left text-xs truncate">
        {field.name}
      </span>
    </div>
  );
};
