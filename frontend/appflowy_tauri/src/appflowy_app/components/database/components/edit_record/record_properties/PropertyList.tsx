import React, { HTMLAttributes, useState } from 'react';
import { Field } from '$app/components/database/application';
import Property from '$app/components/database/components/edit_record/record_properties/Property';
import { Draggable } from 'react-beautiful-dnd';

interface Props extends HTMLAttributes<HTMLDivElement> {
  properties: Field[];
  rowId: string;
  placeholderNode?: React.ReactNode;
}

function PropertyList({ properties, rowId, placeholderNode, ...props }: Props, ref: React.ForwardedRef<HTMLDivElement>) {
  const [hoverId, setHoverId] = useState<string | null>(null);

  return (
    <div ref={ref} {...props} className={'flex w-full flex-col pb-3 pt-2'}>
      {properties.map((field, index) => {
        return (
          <Draggable key={field.id} draggableId={field.id} index={index}>
            {(provided) => (
              <Property
                ref={provided.innerRef}
                {...provided.draggableProps}
                {...provided.dragHandleProps}
                style={{
                  ...provided.draggableProps.style,
                  left: 'auto !important',
                  top: 'auto !important',
                }}
                onHover={setHoverId}
                ishovered={field.id === hoverId}
                field={field}
                rowId={rowId}
              />
            )}
          </Draggable>
        );
      })}
      {placeholderNode}
    </div>
  );
}

export default React.memo(React.forwardRef(PropertyList));
