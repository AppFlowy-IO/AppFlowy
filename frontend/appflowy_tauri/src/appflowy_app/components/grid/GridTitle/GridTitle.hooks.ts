import { useState } from 'react';
import { gridActions } from '../../../redux/grid/slice';

import { useAppDispatch, useAppSelector } from '../../../store';

export const useGridTitleHooks = function () {
  const dispatch = useAppDispatch();
  const grid = useAppSelector((state) => state.grid);

  const [title, setTitle] = useState(grid.title);
  const [changingTitle, setChangingTitle] = useState(false);

  const onTitleChange = (event: React.ChangeEvent<HTMLTextAreaElement>) => {
    setTitle(event.target.value);
  };

  const onTitleBlur = () => {
    dispatch(gridActions.updateGridTitle({ title }));
    setChangingTitle(false);
  };

  const onTitleClick = () => {
    setChangingTitle(true);
  };

  return {
    title,
    onTitleChange,
    onTitleBlur,
    onTitleClick,
    changingTitle,
  };
};
