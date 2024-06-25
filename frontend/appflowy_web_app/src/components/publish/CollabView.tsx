import { ViewLayout, YDoc } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import { usePublishContext } from '@/application/publish';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { Database } from '@/components/database';
import { useViewMeta } from '@/components/publish/useViewMeta';
import { ViewMetaProps } from 'src/components/view-meta';
import React, { useMemo } from 'react';
import { Document } from '@/components/document';
import Y from 'yjs';

export interface CollabViewProps {
  doc?: YDoc;
}

function CollabView({ doc }: CollabViewProps) {
  const { viewId, layout, icon, cover, layoutClassName, style } = useViewMeta();

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
      navigateToView?: (viewId: string) => Promise<void>;
      loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
      getViewRowsMap?: (rowIds: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
      loadView?: (id: string) => Promise<YDoc>;
    } & ViewMetaProps
  >;

  const navigateToView = usePublishContext()?.toView;
  const loadViewMeta = usePublishContext()?.loadViewMeta;
  const getViewRowsMap = usePublishContext()?.getViewRowsMap;
  const loadView = usePublishContext()?.loadView;

  if (!doc) {
    return <ComponentLoading />;
  }

  return (
    <div style={style} className={`relative w-full ${layoutClassName}`}>
      <View
        doc={doc}
        loadViewMeta={loadViewMeta}
        getViewRowsMap={getViewRowsMap}
        navigateToView={navigateToView}
        loadView={loadView}
        icon={icon}
        cover={cover}
        viewId={viewId}
      />
    </div>
  );
}

export default CollabView;
