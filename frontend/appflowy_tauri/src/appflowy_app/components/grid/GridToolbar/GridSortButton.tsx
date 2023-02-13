import { SortSvg } from '../../_shared/svg/SortSvg';

export const GridSortButton = () => {
  return (
    <button className={'flex items-center rounded-lg p-2 text-sm hover:bg-main-selector'}>
      <i className={'mr-2 h-5 w-5'}>
        <SortSvg></SortSvg>
      </i>
      <span>Sort</span>
    </button>
  );
};
