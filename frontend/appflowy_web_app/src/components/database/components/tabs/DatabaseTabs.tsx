import { DatabaseViewLayout, YDatabaseView, YjsDatabaseKey } from '@/application/collab.type';
import { DatabaseContext, useDatabase, useDatabaseView } from '@/application/database-yjs';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { DatabaseActions } from '@/components/database/components/conditions';
import { Tooltip } from '@mui/material';
import { forwardRef, FunctionComponent, SVGProps, useContext, useEffect, useMemo, useState } from 'react';
import { ViewTabs, ViewTab } from './ViewTabs';
import { useTranslation } from 'react-i18next';

import { ReactComponent as GridSvg } from '@/assets/grid.svg';
import { ReactComponent as BoardSvg } from '@/assets/board.svg';
import { ReactComponent as CalendarSvg } from '@/assets/calendar.svg';

export interface DatabaseTabBarProps {
  viewIds: string[];
  selectedViewId?: string;
  setSelectedViewId?: (viewId: string) => void;
  viewName?: string;
  iidIndex: string;
  hideConditions?: boolean;
}

const DatabaseIcons: {
  [key in DatabaseViewLayout]: FunctionComponent<SVGProps<SVGSVGElement> & { title?: string | undefined }>;
} = {
  [DatabaseViewLayout.Grid]: GridSvg,
  [DatabaseViewLayout.Board]: BoardSvg,
  [DatabaseViewLayout.Calendar]: CalendarSvg,
};

export const DatabaseTabs = forwardRef<HTMLDivElement, DatabaseTabBarProps>(
  ({ viewIds, viewName, hideConditions, iidIndex, selectedViewId, setSelectedViewId }, ref) => {
    const { t } = useTranslation();
    const view = useDatabaseView();
    const views = useDatabase().get(YjsDatabaseKey.views);
    const loadViewMeta = useContext(DatabaseContext)?.loadViewMeta;
    const [meta, setMeta] = useState<ViewMeta | null>(null);
    const layout = Number(view?.get(YjsDatabaseKey.layout)) as DatabaseViewLayout;

    const handleChange = (_: React.SyntheticEvent, newValue: string) => {
      setSelectedViewId?.(newValue);
    };

    useEffect(() => {
      void (async () => {
        if (loadViewMeta) {
          try {
            const meta = await loadViewMeta(iidIndex, setMeta);

            setMeta(meta);
          } catch (e) {
            // do nothing
          }
        }
      })();
    }, [loadViewMeta, iidIndex]);

    const className = useMemo(() => {
      const classList = ['-mb-[0.5px] flex items-center overflow-hidden border-line-divider text-text-title'];

      if (layout === DatabaseViewLayout.Calendar) {
        classList.push('border-b');
      }

      return classList.join(' ');
    }, [layout]);

    const showActions = !hideConditions && layout !== DatabaseViewLayout.Calendar;

    if (viewIds.length === 0) return null;
    return (
      <div ref={ref} className={className}>
        <div
          style={{
            width: showActions ? 'calc(100% - 120px)' : '100%',
          }}
          className='flex items-center '
        >
          <ViewTabs
            scrollButtons={false}
            variant='scrollable'
            allowScrollButtonsMobile
            value={selectedViewId}
            onChange={handleChange}
          >
            {viewIds.map((viewId) => {
              const view = views?.get(viewId) as YDatabaseView | null;

              if (!view) return null;
              const layout = Number(view.get(YjsDatabaseKey.layout)) as DatabaseViewLayout;
              const Icon = DatabaseIcons[layout];
              const name = viewId === iidIndex ? viewName : meta?.child_views?.find((v) => v.view_id === viewId)?.name;

              return (
                <ViewTab
                  key={viewId}
                  data-testid={`view-tab-${viewId}`}
                  icon={<Icon className={'h-4 w-4'} />}
                  iconPosition='start'
                  color='inherit'
                  label={
                    <Tooltip title={name} enterDelay={1000} enterNextDelay={1000} placement={'right'}>
                      <span className={'max-w-[120px] truncate'}>{name || t('grid.title.placeholder')}</span>
                    </Tooltip>
                  }
                  value={viewId}
                />
              );
            })}
          </ViewTabs>
        </div>
        {showActions ? <DatabaseActions /> : null}
      </div>
    );
  }
);
