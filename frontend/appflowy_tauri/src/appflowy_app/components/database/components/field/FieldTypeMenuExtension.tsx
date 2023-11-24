import React, { useMemo } from 'react';
import { FieldType } from '@/services/backend';
import { Field, NumberField, SelectField } from '$app/components/database/application';
import SelectFieldActions from '$app/components/database/components/field_types/select/select_field_actions/SelectFieldActions';
import NumberFieldActions from '$app/components/database/components/field_types/number/NumberFieldActions';

function FieldTypeMenuExtension({ field }: { field: Field }) {
  return useMemo(() => {
    switch (field.type) {
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return <SelectFieldActions field={field as SelectField} />;
      case FieldType.Number:
        return <NumberFieldActions field={field as NumberField} />;
      default:
        return null;
    }
  }, [field]);
}

export default FieldTypeMenuExtension;
