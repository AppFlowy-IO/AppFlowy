import React, { useMemo } from 'react';
import { FieldType } from '@/services/backend';
import { DateTimeField, Field, NumberField, SelectField } from '$app/application/database';
import SelectFieldActions from '$app/components/database/components/field_types/select/select_field_actions/SelectFieldActions';
import NumberFieldActions from '$app/components/database/components/field_types/number/NumberFieldActions';
import DateTimeFieldActions from '$app/components/database/components/field_types/date/DateTimeFieldActions';

function PropertyTypeMenuExtension({ field }: { field: Field }) {
  return useMemo(() => {
    switch (field.type) {
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return <SelectFieldActions field={field as SelectField} />;
      case FieldType.Number:
        return <NumberFieldActions field={field as NumberField} />;
      case FieldType.DateTime:
      case FieldType.CreatedTime:
      case FieldType.LastEditedTime:
        return <DateTimeFieldActions field={field as DateTimeField} />;
      default:
        return null;
    }
  }, [field]);
}

export default PropertyTypeMenuExtension;
