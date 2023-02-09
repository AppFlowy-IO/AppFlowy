import { FilterSvg } from '../../_shared/FilterSvg';

export const GridFilterButton = () => {
  return (
    <button className={'flex items-center p-2 hover:bg-main-selector text-sm rounded-lg'}>
      <i className={'w-5 h-5 mr-2'}>
        <FilterSvg></FilterSvg>
      </i>
      <span>Filter</span>
    </button>
  );
};
