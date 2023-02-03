import { useAppSelector } from '../../../store';
import { useNavigate } from 'react-router-dom';

export const useNavigationPanelHooks = function () {
  const folders = useAppSelector((state) => state.folders);
  const pages = useAppSelector((state) => state.pages);
  const width = useAppSelector((state) => state.navigationWidth);

  const navigate = useNavigate();

  const onBorderMouseDown = () => {
    const onMouseMove = (e: MouseEvent) => {
      console.log(e.movementX, e.movementY);
    };

    const onMouseUp = () => {
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
    };

    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);
  };

  return {
    width,

    folders,
    pages,

    navigate,
  };
};
