import { ReactComponent as ExpandMoreIcon } from '$icons/16x/full_view.svg';
import { useNavigateToView } from '@/application/folder-yjs';
import { IdProvider, useId } from '@/components/_shared/context-provider/IdProvider';
import { Database } from '@/components/database';
import { DatabaseNode, EditorElementProps } from '@/components/editor/editor.type';
import { Tooltip } from '@mui/material';
import React, { forwardRef, memo, useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { BlockType } from '@/application/collab.type';

export const DatabaseBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DatabaseNode>>(({ node, children, ...attributes }, ref) => {
    const { t } = useTranslation();
    const viewId = node.data.view_id;
    const workspaceId = useId()?.workspaceId;
    const type = node.type;
    const navigateToView = useNavigateToView();
    const [isHovering, setIsHovering] = useState(false);

    const style = useMemo(() => {
      const style = {};

      switch (type) {
        case BlockType.GridBlock:
          Object.assign(style, {
            height: 360,
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

    const handleNavigateToRow = useCallback(
      (viewId: string, rowId: string) => {
        const url = `/view/${workspaceId}/${viewId}?r=${rowId}`;

        window.open(url, '_blank');
      },
      [workspaceId]
    );

    return (
      <>
        <div
          {...attributes}
          className={`relative w-full cursor-pointer py-2`}
          onMouseEnter={() => setIsHovering(true)}
          onMouseLeave={() => setIsHovering(false)}
        >
          <div ref={ref} className={'absolute left-0 top-0 h-full w-full caret-transparent'}>
            {children}
          </div>
          <div contentEditable={false} style={style} className={`container-bg relative flex w-full flex-col px-3`}>
            {viewId ? (
              <IdProvider workspaceId={workspaceId} objectId={viewId}>
                <Database onNavigateToRow={handleNavigateToRow} />
                {isHovering && (
                  <div className={'absolute right-4 top-1'}>
                    <Tooltip placement={'bottom'} title={t('tooltip.openAsPage')}>
                      <button
                        color={'primary'}
                        className={'rounded border border-line-divider bg-bg-body p-1 hover:bg-fill-list-hover'}
                        onClick={() => {
                          navigateToView?.(viewId);
                        }}
                      >
                        <ExpandMoreIcon />
                      </button>
                    </Tooltip>
                  </div>
                )}
              </IdProvider>
            ) : (
              <div
                className={'mt-[10%] flex h-full w-full flex-col items-center gap-2 px-16 text-text-caption max-md:px-4'}
              >
                <div className={'text-sm font-medium'}>{t('document.plugins.database.noDataSource')}</div>
                <div className={'text-xs'}>{t('grid.relation.noDatabaseSelected')}</div>
              </div>
            )}
          </div>
        </div>
      </>
    );
  })
);

export default DatabaseBlock;
