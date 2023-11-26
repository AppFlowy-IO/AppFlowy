import { Sorts } from '../sort';
import Filters from '../filter/Filters';
import React from 'react';

interface Props {
  open: boolean;
}

export const DatabaseCollection = ({ open }: Props) => {
  return (
    <div className={`flex items-center px-16 ${!open ? 'hidden' : 'py-3'}`}>
      <Sorts />
      <Filters />
    </div>
  );
};
