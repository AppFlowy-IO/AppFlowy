import React, { HTMLAttributes, useState } from 'react';
import { Field } from '$app/components/database/application';
import Property from '$app/components/database/components/edit_record/record_properties/Property';
import { Draggable } from 'react-beautiful-dnd';

interface Props extends HTMLAttributes<HTMLDivElement> {
  documentId?: string;
  properties: Field[];
  rowId: string;
  placeholderNode?: React.ReactNode;
  openMenuPropertyId?: string;
  setOpenMenuPropertyId?: (id?: string) => void;
}

function PropertyList(
  { documentId, properties, rowId, placeholderNode, openMenuPropertyId, setOpenMenuPropertyId, ...props }: Props,
  ref: React.ForwardedRef<HTMLDivElement>
) {
  const [hoverId, setHoverId] = useState<string | null>(null);

  return (
    <div ref={ref} {...props} className={'flex w-full flex-col pb-3 pt-2'}>
      {properties.map((field, index) => {
        return (
          <Draggable key={field.id} draggableId={field.id} index={index}>
            {(provided) => {
              let top;

              if (provided.draggableProps.style && 'top' in provided.draggableProps.style) {
                const scrollContainer = document.querySelector(`#appflowy-scroller_${documentId}`);

                top = provided.draggableProps.style.top - 113 + (scrollContainer?.scrollTop || 0);
              }

              return (
                <Property
                  ref={provided.innerRef}
                  {...provided.draggableProps}
                  {...provided.dragHandleProps}
                  style={{
                    ...provided.draggableProps.style,
                    left: 'auto !important',
                    top: top !== undefined ? top : undefined,
                  }}
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
