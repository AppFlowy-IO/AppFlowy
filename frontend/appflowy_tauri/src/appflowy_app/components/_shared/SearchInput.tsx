import { SearchSvg } from './svg/SearchSvg';
import { useState } from 'react';

export const SearchInput = () => {
  const [active, setActive] = useState(false);

  return (
    <div className={`flex items-center rounded-lg p-2 ${active && 'bg-main-selector'}`}>
      <i className='mr-2 h-5 w-5'>
        <SearchSvg />
      </i>
      <input
        onFocus={() => setActive(true)}
        onBlur={() => setActive(false)}
        className='w-52 text-sm placeholder-gray-400 focus:placeholder-gray-500'
        placeholder='Search'
        type='search'
      />
    </div>
  );
};
