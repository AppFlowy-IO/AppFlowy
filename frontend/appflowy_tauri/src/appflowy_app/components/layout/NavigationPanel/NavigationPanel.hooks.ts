import { useAppSelector } from '../../../stores/store';
import { useNavigate } from 'react-router-dom';
import { IPage } from '../../../stores/reducers/pages/slice';
import { ViewLayoutTypePB } from '../../../../services/backend';

export const useNavigationPanelHooks = function () {
  const folders = useAppSelector((state) => state.folders);
  const pages = useAppSelector((state) => state.pages);
  const width = useAppSelector((state) => state.navigationWidth);

  const navigate = useNavigate();

  const onPageClick = (page: IPage) => {
    let pageTypeRoute = (() => {
      switch (page.pageType) {
        case ViewLayoutTypePB.Document:
          return 'document';
          break;
        case ViewLayoutTypePB.Grid:
          return 'grid';
        case ViewLayoutTypePB.Board:
          return 'board';
        default:
          return 'document';
      }
    })();

    navigate(`/page/${pageTypeRoute}/${page.id}`);
  };

  return {
    width,

    folders,
    pages,

    navigate,
    onPageClick,
  };
};
