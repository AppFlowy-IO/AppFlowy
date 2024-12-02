import { DatabaseViewLayout, UIVariant, View, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/types';
import { Database } from '@/components/database';
import TableContainer from '@/components/editor/components/table-container/TableContainer';
import { DatabaseNode, EditorElementProps } from '@/components/editor/editor.type';
import { useEditorContext } from '@/components/editor/EditorContext';
import { getScrollParent } from '@/components/global-comment/utils';
import CircularProgress from '@mui/material/CircularProgress';
import React, { forwardRef, memo, useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useReadOnly, useSlateStatic } from 'slate-react';

export const DatabaseBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DatabaseNode>>(({ node, children, ...attributes }, ref) => {
    const { t } = useTranslation();
    const viewId = node.data.view_id;
    const context = useEditorContext();
    const navigateToView = context?.navigateToView;
    const loadView = context?.loadView;
    const createRowDoc = context?.createRowDoc;
    const loadViewMeta = context?.loadViewMeta;
    const readSummary = context.readSummary;
    const variant = context.variant;

    const [notFound, setNotFound] = useState(false);
    const [showActions, setShowActions] = useState(false);
    const [doc, setDoc] = useState<YDoc | null>(null);

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
      async (rowId: string) => {
        if (!viewId) return;
        await navigateToView?.(viewId, rowId);
      },
      [navigateToView, viewId],
    );
    const readOnly = useReadOnly();

    const containerRef = useRef<HTMLDivElement | null>(null);
    const handleRendered = useCallback(async (height: number) => {
      const container = containerRef.current;

      if (!container) return;
      if (height > 0) {
        container.style.height = `${height}px`;
      }

      container.style.maxHeight = '550px';

    }, []);

    const [scrollLeft, setScrollLeft] = useState(0);
    const editor = useSlateStatic();

    useEffect(() => {
      const editorDom = ReactEditor.toDOMNode(editor, editor);
      const scrollContainer = getScrollParent(editorDom) as HTMLElement;
      const view = doc?.getMap(YjsEditorKey.data_section)?.get(YjsEditorKey.database)?.get(YjsDatabaseKey.views)?.get(selectedViewId);
      const layout = Number(view?.get(YjsDatabaseKey.layout));

      const onResize = () => {
        const scrollRect = scrollContainer.getBoundingClientRect();

        setScrollLeft(Math.max(editorDom.getBoundingClientRect().left - scrollRect.left, layout === DatabaseViewLayout.Grid ? 64 : 0));
      };

      onResize();

      const resizeObserver = new ResizeObserver(onResize);

      resizeObserver.observe(scrollContainer);
      return () => {
        resizeObserver.disconnect();
      };
    }, [editor, selectedViewId, doc]);

    return (
      <>
        <div
          {...attributes}
          contentEditable={readOnly ? false : undefined}
          className={`relative w-full cursor-pointer`}
          onMouseEnter={() => {
            if (variant === UIVariant.App) {

              setShowActions(true);
            }
          }}
          onMouseLeave={() => setShowActions(false)}
        >
          <div
            ref={ref}
            className={'absolute left-0 top-0 h-full w-full caret-transparent'}
          >
            {children}
          </div>
          <TableContainer
            paddingLeft={scrollLeft}
            blockId={node.blockId}
            readSummary={readSummary}
          >
            <div
              contentEditable={false}
              ref={containerRef}
              className={`container-bg select-none h-[550px] min-h-[270px] my-1 appflowy-scroller overflow-y-auto overflow-x-hidden relative flex w-full flex-col`}
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
                    onOpenRow={handleNavigateToRow}
                    loadViewMeta={loadViewMeta}
                    iidName={iidName}
                    visibleViewIds={visibleViewIds}
                    onChangeView={setSelectedViewId}
                    showActions={showActions}
                    onRendered={handleRendered}
                    scrollLeft={scrollLeft}
                    isDocumentBlock={true}
                  />
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
          </TableContainer>

        </div>
      </>
    );
  }),
  (prevProps, nextProps) => prevProps.node.data.view_id === nextProps.node.data.view_id,
);

export default DatabaseBlock;
