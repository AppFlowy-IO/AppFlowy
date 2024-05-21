import { ViewLayout, YjsFolderKey, YView } from '@/application/collab.type';
import { useFolderContext } from '@/application/folder-yjs';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { DatabaseActions } from '@/components/database/components/conditions';
import { forwardRef, FunctionComponent, SVGProps, useCallback, useEffect, useMemo } from 'react';
import { ViewTabs, ViewTab } from './ViewTabs';
import { useTranslation } from 'react-i18next';

import { ReactComponent as GridSvg } from '$icons/16x/grid.svg';
import { ReactComponent as BoardSvg } from '$icons/16x/board.svg';
import { ReactComponent as CalendarSvg } from '$icons/16x/date.svg';
import { ReactComponent as DocumentSvg } from '$icons/16x/document.svg';

export interface DatabaseTabBarProps {
  viewIds: string[];
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
}

const DatabaseIcons: {
  [key in ViewLayout]: FunctionComponent<SVGProps<SVGSVGElement> & { title?: string | undefined }>;
} = {
  [ViewLayout.Document]: DocumentSvg,
  [ViewLayout.Grid]: GridSvg,
  [ViewLayout.Board]: BoardSvg,
  [ViewLayout.Calendar]: CalendarSvg,
};

export const DatabaseTabs = forwardRef<HTMLDivElement, DatabaseTabBarProps>(
  ({ viewIds, selectedViewId, setSelectedViewId }, ref) => {
    const objectId = useId().objectId;
    const { t } = useTranslation();
    const folder = useFolderContext();
    const handleChange = (_: React.SyntheticEvent, newValue: string) => {
      setSelectedViewId?.(newValue);
    };

    useEffect(() => {
      if (selectedViewId === undefined) {
        setSelectedViewId?.(objectId);
      }
    }, [selectedViewId, setSelectedViewId, objectId]);
    const isSelected = useMemo(() => viewIds.some((viewId) => viewId === selectedViewId), [viewIds, selectedViewId]);

    const getFolderView = useCallback(
      (viewId: string) => {
        if (!folder) return null;
        return folder.get(YjsFolderKey.views)?.get(viewId) as YView | null;
      },
      [folder]
    );

    if (viewIds.length === 0) return null;
    return (
      <div ref={ref} className='mx-24 flex items-center overflow-hidden text-text-title max-md:mx-4'>
        <div
          style={{
            width: 'calc(100% - 120px)',
          }}
          className='flex items-center '
        >
          <ViewTabs
            scrollButtons={false}
            variant='scrollable'
            allowScrollButtonsMobile
            value={isSelected ? selectedViewId : objectId}
            onChange={handleChange}
          >
            {viewIds.map((viewId, index) => {
              const view = getFolderView(viewId);

              if (!view) return null;
              const layout = Number(view.get(YjsFolderKey.layout)) as ViewLayout;
              const Icon = DatabaseIcons[layout];
              const name = view.get(YjsFolderKey.name);

              return (
                <ViewTab
                  key={viewId}
                  style={{
                    borderRight: index === viewIds.length - 1 ? 'none' : '1px solid var(--line-divider)',
                  }}
                  icon={<Icon className={'h-4 w-4'} />}
                  iconPosition='start'
                  color='inherit'
                  label={name || t('grid.title.placeholder')}
                  value={viewId}
                />
              );
            })}
          </ViewTabs>
        </div>
        <DatabaseActions />
      </div>
    );
  }
);
