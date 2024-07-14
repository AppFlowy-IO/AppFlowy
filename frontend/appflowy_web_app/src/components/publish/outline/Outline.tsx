import { PublishViewInfo, ViewLayout } from '@/application/collab.type';
import OutlineItem from '@/components/publish/outline/OutlineItem';
import SearchInput from '@/components/publish/outline/SearchInput';
import { filterViews } from '@/components/publish/outline/utils';
import { CircularProgress } from '@mui/material';
import React, { useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';

function Outline({ viewMeta, width }: { viewMeta?: PublishViewInfo; width: number }) {
  const hasChildren = Boolean(viewMeta?.child_views?.length);
  const { t } = useTranslation();
  const [children, setChildren] = React.useState<PublishViewInfo[]>([]);

  useEffect(() => {
    if (viewMeta) {
      setChildren(viewMeta.child_views || []);
    }
  }, [viewMeta]);

  const handleSearch = useCallback(
    (val: string) => {
      if (!val) {
        return setChildren(viewMeta?.child_views || []);
      }

      setChildren(filterViews(viewMeta?.child_views || [], val));
    },
    [viewMeta]
  );

  if (!viewMeta) {
    return <CircularProgress />;
  }

  return (
    <div className={'flex w-full flex-1 flex-col items-start justify-between gap-2'}>
      <div
        style={{
          position: 'sticky',
          top: 0,
          width: '100%',
          height: '44px',
        }}
        className={'z-10 flex items-center justify-center gap-3 bg-bg-body'}
      >
        <SearchInput onSearch={handleSearch} />
      </div>

      {hasChildren ? (
        <div className={'flex w-full flex-1 flex-col'}>
          {children
            .filter((view) => view.layout === ViewLayout.Document)
            .map((view: PublishViewInfo) => (
              <OutlineItem width={width} key={view.view_id} view={view} />
            ))}
        </div>
      ) : (
        <div className={'flex w-full flex-1 items-center justify-center text-text-caption'}>{t('noPagesInside')}</div>
      )}
    </div>
  );
}

export default Outline;
