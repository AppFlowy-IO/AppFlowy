import { SearchSvg } from './SearchSvg';
import { useState } from 'react';

export const SearchInput = () => {
  const [active, setActive] = useState(false);

  return (
    <div className={`p-2 rounded-lg flex items-center ${active && 'bg-main-selector'}`}>
      <i className='w-5 h-5 mr-2'>
        <SearchSvg />
      </i>
      <input
        onFocus={() => setActive(true)}
        onBlur={() => setActive(false)}
        className='w-52 placeholder-gray-400 text-sm focus:placeholder-gray-500'
        placeholder='Search'
        type='search'
      />
    </div>
  );
};
