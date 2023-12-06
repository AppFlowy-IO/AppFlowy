import React, { useEffect, useState } from 'react';
import { useDatabase } from '$app/components/database';
import { Field as FieldType, fieldService } from '$app/components/database/application';
import { Property } from '$app/components/database/components/property';
import { FieldVisibility } from '@/services/backend';
import { ReactComponent as EyeOpen } from '$app/assets/eye_open.svg';
import { ReactComponent as EyeClosed } from '$app/assets/eye_close.svg';
import { IconButton, MenuItem } from '@mui/material';
import { DragDropContext, Draggable, Droppable, DropResult } from 'react-beautiful-dnd';
import { useViewId } from '$app/hooks';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';

interface PropertiesProps {
  onItemClick: (field: FieldType) => void;
}
function Properties({ onItemClick }: PropertiesProps) {
  const { fields } = useDatabase();
  const [state, setState] = useState<FieldType[]>(fields as FieldType[]);
  const viewId = useViewId();

  useEffect(() => {
    setState(fields as FieldType[]);
  }, [fields]);

  const handleOnDragEnd = async (result: DropResult) => {
    const { destination, draggableId, source } = result;
    const newIndex = destination?.index;
    const oldIndex = source.index;

    if (oldIndex === newIndex) {
      return;
    }

    if (newIndex === undefined || newIndex === null) {
      return;
    }

    const newProperties = fieldService.reorderFields(fields as FieldType[], oldIndex, newIndex ?? 0);

    setState(newProperties);

    await fieldService.moveField(viewId, draggableId, oldIndex, newIndex);
  };

  return (
    <DragDropContext onDragEnd={handleOnDragEnd}>
      <Droppable droppableId='droppable' type='droppableItem'>
        {(dropProvided) => (
          <div
            ref={dropProvided.innerRef}
            {...dropProvided.droppableProps}
            className={'max-h-[300px] overflow-y-auto py-2'}
          >
            {state.map((field, index) => (
              <Draggable key={field.id} draggableId={field.id} index={index}>
                {(provided) => {
                  return (
                    <MenuItem
                      ref={provided.innerRef}
                      {...provided.draggableProps}
                      className={'flex w-full items-center justify-between overflow-hidden px-1.5'}
                      key={field.id}
                    >
                      <IconButton
                        size={'small'}
                        {...provided.dragHandleProps}
                        className='mx-1 cursor-grab active:cursor-grabbing'
                      >
                        <DragSvg />
                      </IconButton>
                      <div className={'w-[100px] overflow-hidden text-ellipsis'}>
                        <Property field={field} />
                      </div>

                      <IconButton
                        disabled={field.isPrimary}
                        size={'small'}
                        onClick={() => onItemClick(field)}
                        className={'ml-2'}
                      >
                        {field.visibility !== FieldVisibility.AlwaysHidden ? <EyeOpen /> : <EyeClosed />}
                      </IconButton>
                    </MenuItem>
                  );
                }}
              </Draggable>
            ))}
            {dropProvided.placeholder}
          </div>
        )}
      </Droppable>
    </DragDropContext>
  );
}

export default Properties;
