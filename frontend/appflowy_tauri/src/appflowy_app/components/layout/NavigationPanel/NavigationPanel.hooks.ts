import { useAppSelector } from '../../../stores/store';
import { useNavigate } from 'react-router-dom';

export const useNavigationPanelHooks = function () {
  const folders = useAppSelector((state) => state.folders);
  const pages = useAppSelector((state) => state.pages);
  const width = useAppSelector((state) => state.navigationWidth);

  const navigate = useNavigate();

  return {
    width,

    folders,
    pages,

    navigate,
  };
};
