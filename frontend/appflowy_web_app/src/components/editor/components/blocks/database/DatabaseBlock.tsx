import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import { BlockType, View, YDoc } from '@/application/types';
import { Database } from '@/components/database';
import { DatabaseNode, EditorElementProps } from '@/components/editor/editor.type';
import { EditorVariant, useEditorContext } from '@/components/editor/EditorContext';
import { Tooltip } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { forwardRef, memo, useCallback, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

export const DatabaseBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DatabaseNode>>(({ node, children, ...attributes }, ref) => {
    const { t } = useTranslation();
    const viewId = node.data.view_id;
    const type = node.type;
    const navigateToView = useEditorContext()?.navigateToView;
    const loadView = useEditorContext()?.loadView;
    const createRowDoc = useEditorContext()?.createRowDoc;
    const loadViewMeta = useEditorContext()?.loadViewMeta;
    const variant = useEditorContext()?.variant;

    const [notFound, setNotFound] = useState(false);
    const [doc, setDoc] = useState<YDoc | null>(null);
    const [isHovering, setIsHovering] = useState(false);
    const style = useMemo(() => {
      const style = {};

      switch (type) {
        case BlockType.GridBlock:
          Object.assign(style, {
            height: 400,
          });
          break;
        case BlockType.CalendarBlock:
        case BlockType.BoardBlock:
          Object.assign(style, {
            height: 560,
          });
      }

      return style;
    }, [type]);

    useEffect(() => {
      if (!viewId) return;
      void (async () => {
        try {
          const view = await loadView?.(viewId);

          if (!view) {
            throw new Error('View not found');
          }

          setDoc(view);
        } catch (e) {
          setNotFound(true);
        }
      })();
    }, [viewId, loadView]);

    const [selectedViewId, setSelectedViewId] = useState<string>(viewId);
    const [visibleViewIds, setVisibleViewIds] = useState<string[]>([]);
    const [iidName, setIidName] = useState<string>('');

    useEffect(() => {
      const updateVisibleViewIds = async (meta: View | null) => {
        if (!meta) {
          return;
        }

        const viewIds = meta.children.map((v) => v.view_id) || [];

        viewIds.unshift(meta.view_id);

        if (!viewIds.includes(viewId)) {
          setSelectedViewId(viewIds[0]);
        } else {
          setSelectedViewId(viewId);
        }

        setIidName(meta.name);
        setVisibleViewIds(viewIds);
      };

      void (async () => {
        try {
          const meta = await loadViewMeta?.(viewId, updateVisibleViewIds);

          if (meta) {
            await updateVisibleViewIds(meta);
          }
        } catch (e) {
          setNotFound(true);
        }
      })();
    }, [loadViewMeta, viewId]);

    const handleNavigateToRow = useCallback(
      (rowId: string) => {
        if (!viewId || variant !== 'app') return;
        window.open(`${window.origin}/app/${viewId}?r=${rowId}`, '_blank');
      },
      [variant, viewId],
    );

    return (
      <>
        <div
          {...attributes}
          contentEditable={false}
          className={`relative w-full cursor-pointer py-2`}
          onMouseEnter={() => setIsHovering(true)}
          onMouseLeave={() => setIsHovering(false)}
        >
          <div
            ref={ref}
            className={'absolute left-0 top-0 h-full w-full caret-transparent'}
          >
            {children}
          </div>
          <div
            contentEditable={false}
            style={style}
            className={`container-bg appflowy-scroller overflow-y-auto overflow-x-hidden relative flex w-full flex-col`}
          >
            {selectedViewId && doc ? (
              <>
                <Database
                  doc={doc}
                  iidIndex={viewId}
                  viewId={selectedViewId}
                  createRowDoc={createRowDoc}
                  loadView={loadView}
                  navigateToView={navigateToView}
                  onOpenRow={variant === 'app' ? handleNavigateToRow : undefined}
                  loadViewMeta={loadViewMeta}
                  iidName={iidName}
                  visibleViewIds={visibleViewIds}
                  onChangeView={setSelectedViewId}
                  hideConditions={variant === EditorVariant.publish}
                />
                {isHovering && (
                  <div className={'absolute right-4 top-1'}>
                    <Tooltip
                      placement={'bottom'}
                      title={t('tooltip.openAsPage')}
                    >
                      <button
                        color={'primary'}
                        className={'rounded border border-line-divider bg-bg-body p-1 hover:bg-fill-list-hover'}
                        onClick={() => {
                          void navigateToView?.(viewId);
                        }}
                      >
                        <ExpandMoreIcon />
                      </button>
                    </Tooltip>
                  </div>
                )}
              </>
            ) : (
              <div
                className={
                  'flex h-full w-full flex-col items-center justify-center gap-2 rounded border border-line-divider bg-fill-list-active px-16 text-text-caption max-md:px-4'
                }
              >
                {notFound ? (
                  <>
                    <div className={'text-base font-medium'}>{t('publish.hasNotBeenPublished')}</div>
                  </>
                ) : (
                  <CircularProgress />
                )}
              </div>
            )}
          </div>
        </div>
      </>
    );
  }),
  (prevProps, nextProps) => prevProps.node.data.view_id === nextProps.node.data.view_id,
);

export default DatabaseBlock;
