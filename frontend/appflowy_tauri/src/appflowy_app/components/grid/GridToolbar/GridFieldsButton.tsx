import { PropertiesSvg } from '../../_shared/PropertiesSvg';

export const GridFieldsButton = () => {
  return (
    <button className={'p-2 flex items-center hover:bg-main-selector text-sm rounded-lg'}>
      <i className={'w-5 h-5 mr-2'}>
        <PropertiesSvg></PropertiesSvg>
      </i>
      <span>Fields</span>
    </button>
  );
};
