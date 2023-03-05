import { useGridTitleHooks } from './GridTitle.hooks';
import { SettingsSvg } from '../../_shared/svg/SettingsSvg';
import { GridTitleOptionsPopup } from './GridTitleOptionsPopup';

export const GridTitle = () => {
  const { title, showOptions, setShowOptions } = useGridTitleHooks();

  return (
    <div className={'relative flex items-center '}>
      <div>{title}</div>

      <div className='flex '>
        <button className={'ml-2 h-5 w-5 '} onClick={() => setShowOptions(!showOptions)}>
          <SettingsSvg></SettingsSvg>
        </button>

        {showOptions && <GridTitleOptionsPopup onClose={() => setShowOptions(!showOptions)} />}
      </div>
    </div>
  );
};
