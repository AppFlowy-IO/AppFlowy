import { FC, FunctionComponent, SVGProps, useEffect } from 'react';
import { ViewTabs, ViewTab } from './ViewTabs';
import { useAppSelector } from '$app/stores/store';
import { useTranslation } from 'react-i18next';
import AddViewBtn from '$app/components/database/components/tab_bar/AddViewBtn';
import { ViewLayoutPB } from '@/services/backend';
import { ReactComponent as GridSvg } from '$app/assets/grid.svg';
import { ReactComponent as BoardSvg } from '$app/assets/board.svg';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';

export interface DatabaseTabBarProps {
  childViewIds: string[];
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
  pageId: string;
}

const DatabaseIcons: {
  [key in ViewLayoutPB]: FunctionComponent<SVGProps<SVGSVGElement> & { title?: string | undefined }>;
} = {
  [ViewLayoutPB.Document]: DocumentSvg,
  [ViewLayoutPB.Grid]: GridSvg,
  [ViewLayoutPB.Board]: BoardSvg,
  [ViewLayoutPB.Calendar]: GridSvg,
};

export const DatabaseTabBar: FC<DatabaseTabBarProps> = ({ pageId, childViewIds, selectedViewId, setSelectedViewId }) => {
  const { t } = useTranslation();
  const views = useAppSelector((state) => {
    const map = state.pages.pageMap;

    return childViewIds.map((id) => map[id]).filter(Boolean);
  });

  const handleChange = (_: React.SyntheticEvent, newValue: string) => {
    setSelectedViewId?.(newValue);
  };

  useEffect(() => {
    if (selectedViewId === undefined && views.length > 0) {
      setSelectedViewId?.(views[0].id);
    }
  }, [selectedViewId, setSelectedViewId, views]);

  return (
    <div className='-mb-px flex items-center border-b border-line-divider'>
      <div className='flex flex-1 items-center'>
        <ViewTabs value={selectedViewId} onChange={handleChange}>
          {views.map((view) => {
            const Icon = DatabaseIcons[view.layout];

            return (
              <ViewTab
                key={view.id}
                icon={<Icon />}
                iconPosition='start'
                color='inherit'
                label={view.name || t('grid.title.placeholder')}
                value={view.id}
              />
            );
          })}
        </ViewTabs>
        <AddViewBtn pageId={pageId} />
      </div>
    </div>
  );
};
