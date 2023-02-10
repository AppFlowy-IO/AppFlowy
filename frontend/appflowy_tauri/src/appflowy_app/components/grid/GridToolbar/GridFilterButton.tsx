import { FilterSvg } from '../../_shared/svg/FilterSvg';

export const GridFilterButton = () => {
  return (
    <button className={'flex items-center rounded-lg p-2 text-sm hover:bg-main-selector'}>
      <i className={'mr-2 h-5 w-5'}>
        <FilterSvg></FilterSvg>
      </i>
      <span>Filter</span>
    </button>
  );
};
