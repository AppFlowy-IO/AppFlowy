import { forwardRef, FunctionComponent, SVGProps, useEffect, useMemo, useState } from 'react';
import { ViewTabs, ViewTab } from './ViewTabs';
import { useTranslation } from 'react-i18next';
import AddViewBtn from '$app/components/database/components/tab_bar/AddViewBtn';
import { ViewLayoutPB } from '@/services/backend';
import { ReactComponent as GridSvg } from '$app/assets/grid.svg';
import { ReactComponent as BoardSvg } from '$app/assets/board.svg';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
import ViewActions from '$app/components/database/components/tab_bar/ViewActions';
import { Page } from '$app_reducers/pages/slice';

export interface DatabaseTabBarProps {
  childViews: Page[];
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

export const DatabaseTabBar = forwardRef<HTMLDivElement, DatabaseTabBarProps>(
  ({ pageId, childViews, selectedViewId, setSelectedViewId }, ref) => {
    const { t } = useTranslation();
    const [contextMenuAnchorEl, setContextMenuAnchorEl] = useState<HTMLElement | null>(null);
    const [contextMenuView, setContextMenuView] = useState<Page | null>(null);
    const open = Boolean(contextMenuAnchorEl);

    const handleChange = (_: React.SyntheticEvent, newValue: string) => {
      setSelectedViewId?.(newValue);
    };

    useEffect(() => {
      if (selectedViewId === undefined && childViews.length > 0) {
        setSelectedViewId?.(childViews[0].id);
      }
    }, [selectedViewId, setSelectedViewId, childViews]);

    const openMenu = (view: Page) => {
      return (e: React.MouseEvent<HTMLElement>) => {
        e.preventDefault();
        e.stopPropagation();
        setContextMenuView(view);
        setContextMenuAnchorEl(e.currentTarget);
      };
    };

    const isSelected = useMemo(
      () => childViews.some((view) => view.id === selectedViewId),
      [childViews, selectedViewId]
    );

    if (childViews.length === 0) return null;
    return (
      <div ref={ref} className='-mb-px flex w-full items-center overflow-hidden px-16  text-text-title'>
        <div
          style={{
            width: 'calc(100% - 120px)',
          }}
          className='flex items-center border-b border-line-divider'
        >
          <ViewTabs
            scrollButtons={false}
            variant='scrollable'
            allowScrollButtonsMobile
            value={isSelected ? selectedViewId : childViews[0].id}
            onChange={handleChange}
          >
            {childViews.map((view) => {
              const Icon = DatabaseIcons[view.layout];

              return (
                <ViewTab
                  onContextMenuCapture={openMenu(view)}
                  onDoubleClick={openMenu(view)}
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
          <AddViewBtn pageId={pageId} onCreated={(id) => setSelectedViewId?.(id)} />
        </div>
        {open && contextMenuView && (
          <ViewActions
            pageId={pageId}
            view={contextMenuView}
            keepMounted={false}
            open={open}
            anchorEl={contextMenuAnchorEl}
            onClose={() => {
              setContextMenuAnchorEl(null);
              setContextMenuView(null);
            }}
          />
        )}
      </div>
    );
  }
);
