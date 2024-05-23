import { Row } from '@/application/database-yjs';
import React from 'react';
import { DraggableProvided, DraggingStyle, NotDraggingStyle } from 'react-beautiful-dnd';
import Card from 'src/components/database/components/board/card/Card';

export const ListItem = ({
  provided,
  item,
  style,
  onResize,
  fieldId,
  isDragging,
}: {
  provided: DraggableProvided;
  item: Row;
  style?: React.CSSProperties;
  fieldId: string;
  onResize?: (height: number) => void;
  isDragging?: boolean;
}) => {
  return (
    <div
      ref={provided.innerRef}
      {...provided.draggableProps}
      {...provided.dragHandleProps}
      style={getStyle({
        draggableStyle: provided.draggableProps.style,
        virtualStyle: style,
        isDragging,
      })}
      className={`w-full bg-bg-body ${isDragging ? 'is-dragging' : ''}`}
    >
      <Card onResize={onResize} rowId={item.id} groupFieldId={fieldId} />
    </div>
  );
};

function getStyle({
  draggableStyle,
  virtualStyle,
  isDragging,
}: {
  draggableStyle?: DraggingStyle | NotDraggingStyle;
  virtualStyle?: React.CSSProperties;
  isDragging?: boolean;
}) {
  // If you don't want any spacing between your items
  // then you could just return this.
  // I do a little bit of magic to have some nice visual space
  // between the row items
  const combined = {
    ...virtualStyle,
    ...draggableStyle,
  } as {
    height: number;
    left: number;
    width: number;
  };

  // Being lazy: this is defined in our css file
  const grid = 1;

  // when dragging we want to use the draggable style for placement, otherwise use the virtual style

  return {
    ...combined,
    height: isDragging ? combined.height : combined.height - grid,
    left: isDragging ? combined.left : combined.left + grid,
    width: isDragging ? (draggableStyle as DraggingStyle)?.width : `calc(${combined.width} - ${grid * 2}px)`,
    marginBottom: grid,
  };
}

export default ListItem;
