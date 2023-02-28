import { useState } from 'react';

import { useAppSelector } from '../../../stores/store';

export const useGridTitleHooks = function () {
  const grid = useAppSelector((state) => state.database);

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
