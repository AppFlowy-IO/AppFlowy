import ButtonPopoverList from '$app/components/_shared/ButtonPopoverList';
import React, { useState } from 'react';
import { SortConditionPB } from '@/services/backend';
import { SortAscSvg } from '$app/components/_shared/svg/SortAscSvg';
import { SortDescSvg } from '$app/components/_shared/svg/SortDescSvg';
import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';

interface IOrderSelectProps {
  currentOrder: SortConditionPB | null;
  onSelectOrderClick: (order: SortConditionPB) => void;
}

const WIDTH = 180;

export const OrderSelect = ({ currentOrder, onSelectOrderClick }: IOrderSelectProps) => {
  const [showSelect, setShowSelect] = useState(false);

  return (
    <ButtonPopoverList
      isVisible={true}
      popoverOptions={[
        {
          icon: (
            <i className={'block h-5 w-5'}>
              <SortAscSvg></SortAscSvg>
            </i>
          ),
          label: 'Ascending',
          key: SortConditionPB.Ascending,
          onClick: () => {
            onSelectOrderClick(SortConditionPB.Ascending);
            setShowSelect(false);
          },
        },
        {
          icon: (
            <i className={'block h-5 w-5'}>
              <SortDescSvg></SortDescSvg>
            </i>
          ),
          label: 'Descending',
          key: SortConditionPB.Descending,
          onClick: () => {
            onSelectOrderClick(SortConditionPB.Descending);
            setShowSelect(false);
          },
        },
      ]}
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
        className={`flex w-[180px] items-center justify-between rounded-lg border px-2 py-1 ${
          showSelect ? 'border-fill-hover' : 'border-line-border'
        }`}
      >
        {currentOrder !== null ? (
          <SortLabel value={currentOrder}></SortLabel>
        ) : (
          <span className={'text-text-caption'}>Select order</span>
        )}
        <i className={`h-5 w-5 transition-transform duration-500 ${showSelect ? 'rotate-180' : 'rotate-0'}`}>
          <DropDownShowSvg></DropDownShowSvg>
        </i>
      </div>
    </ButtonPopoverList>
  );
};

const SortLabel = ({ value }: { value: SortConditionPB }) => {
  return value === SortConditionPB.Ascending ? (
    <div className={'flex items-center gap-2'}>
      <i className={'block h-5 w-5'}>
        <SortAscSvg></SortAscSvg>
      </i>
      <span>Ascending</span>
    </div>
  ) : (
    <div className={'flex items-center gap-2'}>
      <i className={'block h-5 w-5'}>
        <SortDescSvg></SortDescSvg>
      </i>
      <span>Descending</span>
    </div>
  );
};
