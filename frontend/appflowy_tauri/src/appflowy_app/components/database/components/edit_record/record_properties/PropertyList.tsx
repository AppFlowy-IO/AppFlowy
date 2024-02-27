import React, { HTMLAttributes, useState } from 'react';
import { Field } from '$app/application/database';
import Property from '$app/components/database/components/edit_record/record_properties/Property';
import { Draggable } from 'react-beautiful-dnd';

interface Props extends HTMLAttributes<HTMLDivElement> {
  properties: Field[];
  rowId: string;
  placeholderNode?: React.ReactNode;
  openMenuPropertyId?: string;
  setOpenMenuPropertyId?: (id?: string) => void;
}

function PropertyList(
  { properties, rowId, placeholderNode, openMenuPropertyId, setOpenMenuPropertyId, ...props }: Props,
  ref: React.ForwardedRef<HTMLDivElement>
) {
  const [hoverId, setHoverId] = useState<string | null>(null);

  return (
    <div ref={ref} {...props} className={'flex w-full flex-col pb-3 pt-2'}>
      {properties.map((field, index) => {
        return (
          <Draggable key={field.id} draggableId={field.id} index={index}>
            {(provided) => {
              return (
                <Property
                  ref={provided.innerRef}
                  {...provided.draggableProps}
                  {...provided.dragHandleProps}
                  onHover={setHoverId}
                  ishovered={field.id === hoverId}
                  field={field}
                  rowId={rowId}
                  menuOpened={openMenuPropertyId === field.id}
                  onOpenMenu={() => {
                    setOpenMenuPropertyId?.(field.id);
                  }}
                  onCloseMenu={() => {
                    if (openMenuPropertyId === field.id) {
                      setOpenMenuPropertyId?.(undefined);
                    }
                  }}
                />
              );
            }}
          </Draggable>
        );
      })}
      {placeholderNode}
    </div>
  );
}

export default React.forwardRef(PropertyList);
