import { useAppDispatch, useAppSelector } from '@/appflowy_app/stores/store';
import { useState } from 'react';

export const useGridTitleHooks = function () {
  const dispatch = useAppDispatch();
  const grid = useAppSelector((state) => state.database);

  const [showOptions, setShowOptions] = useState(false);

  return {
    showOptions,
    setShowOptions,
  };
};
