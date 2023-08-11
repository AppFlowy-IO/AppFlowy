import ButtonPopoverList from '$app/components/_shared/ButtonPopoverList';
import React, { useState } from 'react';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import { SupportedOperatorsByType, TDatabaseOperators } from '$app_reducers/database/slice';
import { FieldType } from '@/services/backend';

interface IOperatorSelectProps {
  currentOperator: TDatabaseOperators | null;
  currentFieldType: FieldType | undefined;
  onSelectOperatorClick: (operator: TDatabaseOperators) => void;
}

const WIDTH = 180;

export const OperatorSelect = ({ currentOperator, currentFieldType, onSelectOperatorClick }: IOperatorSelectProps) => {
  const [showSelect, setShowSelect] = useState(false);

  return (
    <ButtonPopoverList
      isVisible={true}
      popoverOptions={SupportedOperatorsByType[currentFieldType ? currentFieldType : FieldType.RichText].map(
        (operatorName, index) => ({
          icon: null,
          key: index,
          label: operatorName,
          onClick: () => {
            onSelectOperatorClick(operatorName);
            setShowSelect(false);
          },
        })
      )}
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
        {currentOperator ? (
          <span>{currentOperator}</span>
        ) : (
          <span className={'text-text-placeholder'}>Select an option</span>
        )}
        <i className={`h-5 w-5 transition-transform duration-500 ${showSelect ? 'rotate-180' : 'rotate-0'}`}>
          <DropDownShowSvg></DropDownShowSvg>
        </i>
      </div>
    </ButtonPopoverList>
  );
};
