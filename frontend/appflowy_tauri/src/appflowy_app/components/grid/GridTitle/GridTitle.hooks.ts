import { useAppDispatch, useAppSelector } from '@/appflowy_app/stores/store';
import { useState } from 'react';

export const useGridTitleHooks = function () {
  const dispatch = useAppDispatch();
  const grid = useAppSelector((state) => state.grid);

  const [title, setTitle] = useState(grid.title);
  const [changingTitle, setChangingTitle] = useState(false);
  const [showOptions, setShowOptions] = useState(false);

  const onTitleChange = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    setTitle(event.target.value);
  };

  const onTitleClick = () => {
    setChangingTitle(true);
  };

  return {
    title,
    onTitleChange,
    onTitleClick,
    changingTitle,
    showOptions,
    setShowOptions,
  };
};
