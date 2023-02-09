import { useGridTitleHooks } from './GridTitle.hooks';
import { SettingsSvg } from '../../_shared/SettingsSvg';

export const GridTitle = () => {
  const { title } = useGridTitleHooks();

  return (
    <div className={'text-xl font-semibold flex items-center'}>
      <div>{title}</div>
      <button className={'ml-2 w-5 h-5'}>
        <SettingsSvg></SettingsSvg>
      </button>
    </div>
  );
};
