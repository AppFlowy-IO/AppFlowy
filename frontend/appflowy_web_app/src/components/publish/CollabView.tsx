import { ViewLayout, YDoc } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { usePublishContext } from '@/application/publish';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { useAppThemeMode } from '@/components/app/useAppThemeMode';
import { Database } from '@/components/database';
import { Document } from '@/components/document';
import { useViewMeta } from '@/components/publish/useViewMeta';
import React, { useMemo } from 'react';
import { ViewMetaProps } from 'src/components/view-meta';
import Y from 'yjs';

export interface CollabViewProps {
  doc?: YDoc;
}

function CollabView({ doc }: CollabViewProps) {
  const { viewId, layout, icon, cover, layoutClassName, style, name } = useViewMeta();
  const { isDark } = useAppThemeMode();
  const View = useMemo(() => {
    switch (layout) {
      case ViewLayout.Document:
        return Document;
      case ViewLayout.Grid:
      case ViewLayout.Board:
      case ViewLayout.Calendar:
        return Database;
      default:
        return null;
    }
  }, [layout]) as React.FC<
    {
      doc: YDoc;
      isDark: boolean;
      navigateToView?: (viewId: string) => Promise<void>;
      loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
      getViewRowsMap?: (viewId: string, rowIds: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
      loadView?: (id: string) => Promise<YDoc>;
    } & ViewMetaProps
  >;

  const navigateToView = usePublishContext()?.toView;
  const loadViewMeta = usePublishContext()?.loadViewMeta;
  const getViewRowsMap = usePublishContext()?.getViewRowsMap;
  const loadView = usePublishContext()?.loadView;

  if (!doc || !View) {
    return <ComponentLoading />;
  }

  return (
    <div style={style} className={`relative w-full flex-1 ${layoutClassName}`}>
      <View
        doc={doc}
        loadViewMeta={loadViewMeta}
        getViewRowsMap={getViewRowsMap}
        navigateToView={navigateToView}
        loadView={loadView}
        icon={icon}
        cover={cover}
        viewId={viewId}
        name={name}
        isDark={isDark}
        layout={layout || ViewLayout.Document}
      />
    </div>
  );
}

export default CollabView;
