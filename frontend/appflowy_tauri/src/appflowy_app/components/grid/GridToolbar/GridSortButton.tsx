import { SortSvg } from '../../_shared/SortSvg';

export const GridSortButton = () => {
  return (
    <button className={'p-2 flex items-center hover:bg-main-selector text-sm rounded-lg'}>
      <i className={'w-5 h-5 mr-2'}>
        <SortSvg></SortSvg>
      </i>
      <span>Sort</span>
    </button>
  );
};
