import React from 'react';
import { ReactComponent as ChevronDownIcon } from '@/assets/chevron_down.svg';

function OutlineIcon ({ isExpanded, setIsExpanded, level }: {
  isExpanded: boolean;
  setIsExpanded: (isExpanded: boolean) => void;
  level: number;
}) {
  if (isExpanded) {
    return (
      <button
        style={{
          paddingLeft: 1.125 * level + 'em',
        }}
        onClick={(e) => {
          e.stopPropagation();
          setIsExpanded(false);
        }}
        className={'opacity-50 hover:opacity-100'}
      >
        <ChevronDownIcon className={'h-[1em] w-[1em]  hover:bg-fill-list-hover rounded-[2px]'} />
      </button>
    );
  }

  return (
    <button
      style={{
        paddingLeft: 1.125 * level + 'em',
      }}
      className={'opacity-50 hover:opacity-100'}
      onClick={(e) => {
        e.stopPropagation();
        setIsExpanded(true);
      }}
    >
      <ChevronDownIcon className={'h-[1em] w-[1em] -rotate-90 transform'} />
    </button>
  );
}

export default OutlineIcon;