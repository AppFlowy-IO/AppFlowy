import { Sorts } from '../sort';
import Filters from '../filter/Filters';
import React from 'react';

interface Props {
  open: boolean;
}

export const DatabaseCollection = ({ open }: Props) => {
  return (
    <div className={`database-collection w-full px-[64px] ${!open ? 'hidden' : 'py-3'}`}>
      <div className={'flex w-full items-center gap-2 overflow-x-auto overflow-y-hidden '}>
        <Sorts />
        <Filters />
      </div>
    </div>
  );
};
