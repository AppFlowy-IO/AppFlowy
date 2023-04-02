import { EarthSvg } from '$app/components/_shared/svg/EarthSvg';
import { useState } from 'react';
import { LanguageSelectPopup } from '$app/components/_shared/LanguageSelectPopup';

export const LanguageButton = () => {
  const [showPopup, setShowPopup] = useState(false);
  return (
    <>
      <button onClick={() => setShowPopup(!showPopup)} className={'h-5 w-5'}>
        <EarthSvg></EarthSvg>
      </button>
      {showPopup && <LanguageSelectPopup onClose={() => setShowPopup(false)}></LanguageSelectPopup>}
    </>
  );
};
