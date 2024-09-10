import { GetViewRowsMap, LoadView, LoadViewMeta, ViewLayout, YDoc } from '@/application/types';
import { usePublishContext } from '@/application/publish';
import ViewHelmet from '@/components/_shared/helmet/ViewHelmet';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { Document } from '@/components/document';
import DatabaseView from '@/components/publish/DatabaseView';
import { useViewMeta } from '@/components/publish/useViewMeta';
import React, { useMemo } from 'react';
import { ViewMetaProps } from '@/components/view-meta';

export interface CollabViewProps {
  doc?: YDoc;
}

function CollabView ({ doc }: CollabViewProps) {
  const visibleViewIds = usePublishContext()?.viewMeta?.visible_view_ids;
  const { viewId, layout, icon, cover, layoutClassName, style, name } = useViewMeta();
  const View = useMemo(() => {
    switch (layout) {
      case ViewLayout.Document:
        return Document;
      case ViewLayout.Grid:
      case ViewLayout.Board:
      case ViewLayout.Calendar:
        return DatabaseView;
      default:
        return null;
    }
  }, [layout]) as React.FC<{
    doc: YDoc;
    navigateToView?: (viewId: string) => Promise<void>;
    loadViewMeta?: LoadViewMeta;
    getViewRowsMap?: GetViewRowsMap;
    loadView?: LoadView;
    viewMeta: ViewMetaProps;
    isTemplateThumb?: boolean;
  }>;

  const navigateToView = usePublishContext()?.toView;
  const loadViewMeta = usePublishContext()?.loadViewMeta;
  const getViewRowsMap = usePublishContext()?.getViewRowsMap;
  const loadView = usePublishContext()?.loadView;
  const isTemplateThumb = usePublishContext()?.isTemplateThumb;

  const className = useMemo(() => {
    const classList = ['relative w-full flex-1'];

    if (isTemplateThumb && layout !== ViewLayout.Document) {
      classList.push('flex justify-center h-full');
    }

    if (layoutClassName) {
      classList.push(layoutClassName);
    }

    return classList.join(' ');
  }, [isTemplateThumb, layout, layoutClassName]);

  if (!doc || !View) {
    return <ComponentLoading />;
  }

  return (
    <>
      <ViewHelmet icon={icon} name={name} />

      <div
        style={style}
        className={className}
      >
        <View
          doc={doc}
          loadViewMeta={loadViewMeta}
          getViewRowsMap={getViewRowsMap}
          navigateToView={navigateToView}
          loadView={loadView}
          isTemplateThumb={isTemplateThumb}
          viewMeta={{
            icon,
            cover,
            viewId,
            name,
            layout: layout || ViewLayout.Document,
            visibleViewIds: visibleViewIds || [],
          }}
        />
      </div>
    </>

  );
}

export default CollabView;
