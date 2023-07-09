import { IPopupItem, PopupSelect } from '../../_shared/PopupSelect';
import { FilterSvg } from '../../_shared/svg/FilterSvg';
import { GroupBySvg } from '../../_shared/svg/GroupBySvg';
import { PropertiesSvg } from '../../_shared/svg/PropertiesSvg';
import { SortSvg } from '../../_shared/svg/SortSvg';

export const GridTitleOptionsPopup = ({ onClose }: { onClose?: () => void }) => {
  const items: IPopupItem[] = [
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-text-title'}>
          <FilterSvg />
        </i>
      ),
      onClick: () => {
        console.log('filter');
      },
      title: 'Filter',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-text-title'}>
          <SortSvg />
        </i>
      ),
      onClick: () => {
        console.log('sort');
      },
      title: 'Sort',
    },
    {
      icon: (
        <i className={'h-[16px] w-[16px] text-text-title'}>
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
        <i className={'h-[16px] w-[16px] text-text-title'}>
          <GroupBySvg />
        </i>
      ),
      onClick: () => {
        console.log('group by');
      },
      title: 'Group by',
    },
  ];

  return <PopupSelect items={items} className={'absolute top-full z-10 w-fit'} onOutsideClick={onClose} />;
};
