import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Field, fieldService, RowMeta } from '$app/application/database';
import { useDatabase } from '$app/components/database';
import { FieldVisibility } from '@/services/backend';

import PropertyList from '$app/components/database/components/edit_record/record_properties/PropertyList';
import NewProperty from '$app/components/database/components/property/NewProperty';
import { useViewId } from '$app/hooks';
import { DragDropContext, Droppable, DropResult, OnDragEndResponder } from 'react-beautiful-dnd';
import SwitchPropertiesVisible from '$app/components/database/components/edit_record/record_properties/SwitchPropertiesVisible';

interface Props {
  row: RowMeta;
}

function RecordProperties({ row }: Props) {
  const viewId = useViewId();
  const { fields } = useDatabase();
  const fieldId = useMemo(() => {
    return fields.find((field) => field.isPrimary)?.id;
  }, [fields]);
  const rowId = row.id;
  const [openMenuPropertyId, setOpenMenuPropertyId] = useState<string | undefined>(undefined);
  const [showHiddenFields, setShowHiddenFields] = useState(false);

  const properties = useMemo(() => {
    return fields.filter((field) => {
      // exclude the current field, because it's already displayed in the title
      // filter out hidden fields if the user doesn't want to see them
      return field.id !== fieldId && (showHiddenFields || field.visibility !== FieldVisibility.AlwaysHidden);
    });
  }, [fieldId, fields, showHiddenFields]);

  const hiddenFieldsCount = useMemo(() => {
    return fields.filter((field) => {
      return field.visibility === FieldVisibility.AlwaysHidden;
    }).length;
  }, [fields]);

  const [state, setState] = useState<Field[]>(properties);

  useEffect(() => {
    setState(properties);
  }, [properties]);

  // move the field in the state
  const handleOnDragEnd: OnDragEndResponder = useCallback(
    async (result: DropResult) => {
      const { destination, draggableId, source } = result;
      const newIndex = destination?.index;
      const oldIndex = source.index;

      if (newIndex === undefined || newIndex === null) {
        return;
      }

      const newId = properties[newIndex ?? 0].id;

      // reorder the properties synchronously to avoid flickering
      const newProperties = fieldService.reorderFields(properties, oldIndex, newIndex ?? 0);

      setState(newProperties);

      await fieldService.moveField(viewId, draggableId, newId);
    },
    [properties, viewId]
  );

  return (
    <div className={'relative flex w-full flex-col pb-4'}>
      <DragDropContext onDragEnd={handleOnDragEnd}>
        <Droppable droppableId='droppable' type='droppableItem'>
          {(dropProvided) => (
            <PropertyList
              {...dropProvided.droppableProps}
              placeholderNode={dropProvided.placeholder}
              ref={dropProvided.innerRef}
              rowId={rowId}
              properties={state}
              openMenuPropertyId={openMenuPropertyId}
              setOpenMenuPropertyId={setOpenMenuPropertyId}
            />
          )}
        </Droppable>
      </DragDropContext>
      <SwitchPropertiesVisible
        hiddenFieldsCount={hiddenFieldsCount}
        showHiddenFields={showHiddenFields}
        setShowHiddenFields={setShowHiddenFields}
      />

      <NewProperty onInserted={setOpenMenuPropertyId} />
    </div>
  );
}

export default RecordProperties;
