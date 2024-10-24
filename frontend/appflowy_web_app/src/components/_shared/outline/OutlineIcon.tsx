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
        onClick={() => {
          setIsExpanded(false);
        }}
        className={'opacity-50 hover:opacity-100'}
      >
        <ChevronDownIcon className={'h-[1em] w-[1em]'} />
      </button>
    );
  }

  return (
    <button
      style={{
        paddingLeft: 1.125 * level + 'em',
      }}
      className={'opacity-50 hover:opacity-100'}
      onClick={() => {
        setIsExpanded(true);
      }}
    >
      <ChevronDownIcon className={'h-[1em] w-[1em] -rotate-90 transform'} />
    </button>
  );
}

export default OutlineIcon;