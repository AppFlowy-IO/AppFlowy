import React from 'react';
import { SelectOption } from '$app/components/database/application';
import Option from './Option';

interface Props {
  options: SelectOption[];
  fieldId: string;
}
function Options({ options, fieldId }: Props) {
  return (
    <>
      {options.map((option) => {
        return <Option fieldId={fieldId} key={option.id} option={option} />;
      })}
    </>
  );
}

export default Options;
