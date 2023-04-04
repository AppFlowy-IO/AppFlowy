import { Button } from '../../_shared/Button';
import { Details2Svg } from '../../_shared/svg/Details2Svg';
import { usePageOptions } from './PageOptions.hooks';
import { OptionsPopup } from './OptionsPopup';
import { LanguageButton } from '$app/components/layout/HeaderPanel/LanguageButton';

export const PageOptions = () => {
  const { showOptionsPopup, onOptionsClick, onClose, onSignOutClick } = usePageOptions();

  return (
    <>
      <div className={'relative flex items-center gap-4'}>
        <Button size={'small'} onClick={() => console.log('share click')}>
          Share
        </Button>

        <LanguageButton></LanguageButton>

        <button id='option-button' className={'relative h-8 w-8'} onClick={onOptionsClick}>
          <Details2Svg></Details2Svg>
        </button>
      </div>
      {showOptionsPopup && <OptionsPopup onSignOutClick={onSignOutClick} onClose={onClose}></OptionsPopup>}
    </>
  );
};
