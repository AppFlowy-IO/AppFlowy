import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Field, fieldService, RowMeta } from '$app/components/database/application';
import { useDatabase } from '$app/components/database';
import { FieldVisibility } from '@/services/backend';

import PropertyList from '$app/components/database/components/edit_record/record_properties/PropertyList';
import NewProperty from '$app/components/database/components/property/NewProperty';
import { useViewId } from '$app/hooks';
import { DragDropContext, Droppable, DropResult, OnDragEndResponder } from 'react-beautiful-dnd';
import SwitchPropertiesVisible from '$app/components/database/components/edit_record/record_properties/SwitchPropertiesVisible';

interface Props {
  documentId?: string;
  row: RowMeta;
}

function RecordProperties({ documentId, row }: Props) {
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

  // move the field in the database
  const onMoveProperty = useCallback(
    async (fieldId: string, prevId?: string) => {
      const fromIndex = fields.findIndex((field) => field.id === fieldId);

      const prevIndex = prevId ? fields.findIndex((field) => field.id === prevId) : 0;
      const toIndex = prevIndex > fromIndex ? prevIndex : prevIndex + 1;

      if (fromIndex === toIndex) {
        return;
      }

      await fieldService.moveField(viewId, fieldId, fromIndex, toIndex);
    },
    [fields, viewId]
  );

  // move the field in the state
  const handleOnDragEnd: OnDragEndResponder = useCallback(
    async (result: DropResult) => {
      const { destination, draggableId, source } = result;
      const newIndex = destination?.index;
      const oldIndex = source.index;

      if (newIndex === undefined || newIndex === null) {
        return;
      }

      // reorder the properties synchronously to avoid flickering
      const newProperties = fieldService.reorderFields(properties, oldIndex, newIndex ?? 0);

      setState(newProperties);

      // find the previous field id
      const prevIndex = newProperties.findIndex((field) => field.id === draggableId) - 1;
      const prevId = prevIndex >= 0 ? newProperties[prevIndex].id : undefined;

      // update the order in the database.
      // why not prevIndex? because the properties was filtered, we need to use the previous id to find the correct index
      await onMoveProperty(draggableId, prevId);
    },
    [onMoveProperty, properties]
  );

  return (
    <div className={'relative flex w-full flex-col pb-4'}>
      <DragDropContext onDragEnd={handleOnDragEnd}>
        <Droppable droppableId='droppable' type='droppableItem'>
          {(dropProvided) => (
            <PropertyList
              documentId={documentId}
              placeholderNode={dropProvided.placeholder}
              ref={dropProvided.innerRef}
              {...dropProvided.droppableProps}
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
