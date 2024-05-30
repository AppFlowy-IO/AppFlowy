import { useRowsByGroup } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Column } from '../column';

export interface GroupProps {
  groupId: string;
}

export const Group = ({ groupId }: GroupProps) => {
  const { columns, groupResult, fieldId, notFound } = useRowsByGroup(groupId);

  const { t } = useTranslation();

  if (notFound) {
    return (
      <div className={'mt-[10%] flex h-full w-full flex-col items-center gap-2 px-16 text-text-caption max-md:px-4'}>
        <div className={'text-sm font-medium'}>{t('board.noGroup')}</div>
        <div className={'text-xs'}>{t('board.noGroupDesc')}</div>
      </div>
    );
  }

  if (columns.length === 0 || !fieldId) return null;
  return (
    <AFScroller overflowYHidden className={'relative px-16 max-md:px-4'}>
      <div className='columns flex h-full w-fit min-w-full gap-4 border-t border-line-divider py-4'>
        {columns.map((data) => (
          <Column key={data.id} id={data.id} fieldId={fieldId} rows={groupResult.get(data.id)} />
        ))}
      </div>
    </AFScroller>
  );
};

export default Group;
