import { Row } from '@/application/database-yjs';
import React from 'react';
import Card from 'src/components/database/components/board/card/Card';

export const ListItem = ({
  item,
  style,
  onResize,
  fieldId,
}: {
  item?: Row;
  style?: React.CSSProperties;
  fieldId: string;
  onResize?: (height: number) => void;
}) => {
  return (
    <div
      style={{
        ...style,
        width: 'calc(100% - 2px)',
      }}
      className={`w-full bg-bg-body`}
    >
      {item?.id ? <Card onResize={onResize} rowId={item.id} groupFieldId={fieldId} /> : null}
    </div>
  );
};

export default ListItem;
