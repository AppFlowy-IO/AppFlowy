import { useAppSelector } from '$app/stores/store';
import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { TypeOptionController } from '@/appflowy_app/stores/effects/database/field/type_option/type_option_controller';
import { None } from 'ts-results';

export const useGridTableHeaderHooks = function (controller: DatabaseController) {
  const database = useAppSelector((state) => state.database);

  const onAddField = async () => {
    // TODO: move this to database controller hook
    const fieldController = new TypeOptionController(controller.viewId, None);

    await fieldController.initialize();
  };

  return {
    fields: Object.values(database.fields).map((field) => {
      return {
        fieldId: field.fieldId,
        name: field.title,
        fieldType: field.fieldType,
      };
    }),
    onAddField,
  };
};
