import { useGridTitleHooks } from './GridTitle.hooks';
import { SettingsSvg } from '../../_shared/svg/SettingsSvg';

export const GridTitle = () => {
  const { title } = useGridTitleHooks();

  return (
    <div className={'flex items-center text-xl font-semibold'}>
      <div>{title}</div>
      <button className={'ml-2 h-5 w-5'}>
        <SettingsSvg></SettingsSvg>
      </button>
    </div>
  );
};
