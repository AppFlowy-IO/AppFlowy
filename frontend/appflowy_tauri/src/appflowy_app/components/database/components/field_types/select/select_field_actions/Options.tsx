import React from 'react';
import { SelectOption } from '$app/application/database';
import Option from './Option';

interface Props {
  options: SelectOption[];
  fieldId: string;
}
function Options({ options, fieldId }: Props) {
  return (
    <div>
      {options.map((option) => {
        return <Option fieldId={fieldId} key={option.id} option={option} />;
      })}
    </div>
  );
}

export default Options;
