import { useDatabaseContext, useRowsByGroup } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import React, { useCallback, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { Column } from '../column';

export interface GroupProps {
  groupId: string;
}

export const Group = ({ groupId }: GroupProps) => {
  const { columns, groupResult, fieldId, notFound } = useRowsByGroup(groupId);
  const { t } = useTranslation();
  const context = useDatabaseContext();
  const scrollLeft = context.scrollLeft;
  const maxHeightRef = useRef<number>(0);

  const onRendered = useCallback((height: number) => {
    maxHeightRef.current = Math.max(maxHeightRef.current, height);

    context?.onRendered?.(maxHeightRef.current);
  }, [context]);

  if (notFound) {
    return (
      <div className={'mt-[10%] flex h-full w-full flex-col items-center gap-2 text-text-caption'}>
        <div className={'text-sm font-medium'}>{t('board.noGroup')}</div>
        <div className={'text-xs'}>{t('board.noGroupDesc')}</div>
      </div>
    );
  }

  if (columns.length === 0 || !fieldId) return null;
  return (
    <AFScroller
      overflowYHidden
      className={`relative  h-full`}
    >
      <div
        className={'max-sm:!px-6 px-24 h-full'}
        style={{
          paddingInline: scrollLeft === undefined ? undefined : scrollLeft,
        }}
      >
        <div
          className="columns flex h-full w-fit min-w-full gap-4 border-t border-line-divider py-4"
        >
          {columns.map((data) => (
            <Column
              key={data.id}
              id={data.id}
              fieldId={fieldId}
              rows={groupResult.get(data.id)}
              onRendered={onRendered}
            />
          ))}
        </div>
      </div>
    </AFScroller>
  );
};

export default Group;
