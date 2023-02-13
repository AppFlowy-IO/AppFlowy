import { PropertiesSvg } from '../../_shared/svg/PropertiesSvg';

export const GridFieldsButton = () => {
  return (
    <button className={'flex items-center rounded-lg p-2 text-sm hover:bg-main-selector'}>
      <i className={'mr-2 h-5 w-5'}>
        <PropertiesSvg></PropertiesSvg>
      </i>
      <span>Fields</span>
    </button>
  );
};
