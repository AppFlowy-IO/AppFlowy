import { useState } from 'react';

export const useGridTitleOptionsPopupHooks = function () {
  const [showFilterPopup, setShowFilterPopup] = useState(false);
  const [showSortPopup, setShowSortPopup] = useState(false);

  return {
    showFilterPopup,
    setShowFilterPopup,
    showSortPopup,
    setShowSortPopup,
  };
};
