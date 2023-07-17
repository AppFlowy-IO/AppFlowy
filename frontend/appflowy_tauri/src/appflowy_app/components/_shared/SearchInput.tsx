import { SearchSvg } from './svg/SearchSvg';
import { useState } from 'react';

export const SearchInput = () => {
  const [active, setActive] = useState(false);

  return (
    <div className={`flex items-center rounded-lg border p-2 ${active ? 'border-fill-default' : 'border-line-divider'}`}>
      <i className='mr-2 h-5 w-5'>
        <SearchSvg />
      </i>
      <input
        onFocus={() => setActive(true)}
        onBlur={() => setActive(false)}
        className='w-52 text-sm text-text-placeholder focus:text-text-title'
        placeholder='Search'
        type='search'
      />
    </div>
  );
};
