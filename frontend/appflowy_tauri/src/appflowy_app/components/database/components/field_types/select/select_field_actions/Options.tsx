import React from 'react';
import { SelectOption } from '$app/components/database/application';
import Option from './Option';

interface Props {
  options: SelectOption[];
  fieldId: string;
}
function Options({ options, fieldId }: Props) {
  return (
    <div className={'max-h-[300px] overflow-y-auto overflow-x-hidden'}>
      {options.map((option) => {
        return <Option fieldId={fieldId} key={option.id} option={option} />;
      })}
    </div>
  );
}

export default Options;
