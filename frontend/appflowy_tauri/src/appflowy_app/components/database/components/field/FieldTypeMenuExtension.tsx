import React, { useMemo } from 'react';
import { FieldType } from '@/services/backend';
import { Field, SelectField } from '$app/components/database/application';
import SelectFieldActions from '$app/components/database/components/field_types/select/select_field_actions/SelectFieldActions';

function FieldTypeMenuExtension({ field }: { field: Field }) {
  return useMemo(() => {
    switch (field.type) {
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return <SelectFieldActions field={field as SelectField} />;
      default:
        return null;
    }
  }, [field]);
}

export default FieldTypeMenuExtension;
