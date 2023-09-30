import { IPopupItem, PopupSelect } from '../../_shared/PopupSelect';
import { FilterSvg } from '../../_shared/svg/FilterSvg';
import { GroupBySvg } from '../../_shared/svg/GroupBySvg';
import { PropertiesSvg } from '../../_shared/svg/PropertiesSvg';
import { SortSvg } from '../../_shared/svg/SortSvg';

export const GridTitleOptionsPopup = ({
  onClose,
  onFilterClick,
  onSortClick,
}: {
  onClose?: () => void;
  onFilterClick: () => void;
  onSortClick: () => void;
}) => {
  const items: IPopupItem[] = [
    {
      icon: (
        <i className={'h-[16px] w-[16px] flex-shrink-0 text-text-title'}>
          <FilterSvg />
        </i>
      ),
      onClick: () => {
        onFilterClick && onFilterClick();
        onClose && onClose();
      },
      title: 'Filter',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] flex-shrink-0 text-text-title'}>
          <SortSvg />
        </i>
      ),
      onClick: () => {
        onSortClick && onSortClick();
        onClose && onClose();
      },
      title: 'Sort By',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] flex-shrink-0 text-text-title'}>
          <PropertiesSvg />
        </i>
      ),
      onClick: () => {
        console.log('fields');
      },
      title: 'Fields',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] flex-shrink-0 text-text-title'}>
          <GroupBySvg />
        </i>
      ),
      onClick: () => {
        console.log('group by');
      },
      title: 'Group by',
    },
  ];

  return <PopupSelect items={items} className={'absolute top-full z-10 w-[140px]'} onOutsideClick={onClose} />;
};
