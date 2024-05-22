import { useRowsByGroup } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import React from 'react';
import { Draggable, Droppable } from 'react-beautiful-dnd';
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
      <div className={'mt-[10%] flex h-full w-full flex-col items-center gap-2 px-24 text-text-caption max-md:px-4'}>
        <div className={'text-sm font-medium'}>{t('board.noGroup')}</div>
        <div className={'text-xs'}>{t('board.noGroupDesc')}</div>
      </div>
    );
  }

  if (columns.length === 0 || !fieldId) return null;
  return (
    <AFScroller overflowYHidden className={'relative px-24 max-md:px-4'}>
      <Droppable
        droppableId={`group-${groupId}`}
        direction='horizontal'
        type='column'
        renderClone={(provided, snapshot, rubric) => {
          // we have a transform: * on one of the parents of a <Draggable /> then the positioning logic will be incorrect while dragging
          // https://github.com/atlassian/react-beautiful-dnd/blob/master/docs/guides/reparenting.md
          const id = columns[rubric.source.index].id;

          return <Column key={id} rows={groupResult.get(id)} provided={provided} id={id} fieldId={fieldId} />;
        }}
      >
        {(provided) => {
          return (
            <div
              className='columns flex h-full w-fit gap-4 border-t border-line-divider py-4'
              {...provided.droppableProps}
              ref={provided.innerRef}
            >
              {columns.map((data, index) => (
                <Draggable isDragDisabled key={data.id} draggableId={`column-${data.id}`} index={index}>
                  {(provided) => {
                    return (
                      <Column
                        provided={provided}
                        key={data.id}
                        id={data.id}
                        fieldId={fieldId}
                        rows={groupResult.get(data.id)}
                      />
                    );
                  }}
                </Draggable>
              ))}
            </div>
          );
        }}
      </Droppable>
    </AFScroller>
  );
};

export default Group;
