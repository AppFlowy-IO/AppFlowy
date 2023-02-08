import { SearchSvg } from './SearchSvg';

export const SearchInput = () => {
  return (
    <div className='relative'>
      <span className='absolute inset-y-0 left-0 flex items-center pl-3'>
        <SearchSvg />
      </span>
      <div className='w-52'>
        <input
          className='block w-full pl-10 pr-3   border border-none  rounded-md leading-5 bg-white placeholder-gray-400 focus:outline-none focus:placeholder-gray-500 sm:text-sm'
          placeholder='Search'
          type='search'
        />
      </div>
    </div>
  );
};
