import ButtonPopoverList from '$app/components/_shared/ButtonPopoverList';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import React, { useState } from 'react';

const LogicalOperators: ('and' | 'or')[] = ['and', 'or'];
const WIDTH = 88;

export const LogicalOperatorSelect = () => {
  const [showSelect, setShowSelect] = useState(false);

  return (
    <ButtonPopoverList
      isVisible={true}
      popoverOptions={LogicalOperators.map((operator) => ({
        key: operator,
        label: operator,
        icon: null,
        onClick: () => {
          console.log('logical operator: ', operator);
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
        and
        <i className={`h-5 w-5 transition-transform duration-500 ${showSelect ? 'rotate-180' : 'rotate-0'}`}>
          <DropDownShowSvg></DropDownShowSvg>
        </i>
      </div>
    </ButtonPopoverList>
  );
};
