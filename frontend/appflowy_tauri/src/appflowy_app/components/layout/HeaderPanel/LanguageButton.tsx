import { useState } from 'react';
import { LanguageSelectPopup } from '$app/components/_shared/LanguageSelectPopup';
import { LanguageOutlined } from '@mui/icons-material';

export const LanguageButton = () => {
  const [showPopup, setShowPopup] = useState(false);

  return (
    <>
      <button onClick={() => setShowPopup(!showPopup)} className={'h-8 w-8 rounded text-text-title hover:bg-fill-hover'}>
        <LanguageOutlined />
      </button>
      {showPopup && <LanguageSelectPopup onClose={() => setShowPopup(false)}></LanguageSelectPopup>}
    </>
  );
};
