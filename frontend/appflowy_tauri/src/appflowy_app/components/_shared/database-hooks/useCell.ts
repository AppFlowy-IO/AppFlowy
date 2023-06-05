import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { CellControllerBuilder } from '$app/stores/effects/database/cell/controller_builder';
import { DateCellDataPB, SelectOptionCellDataPB, URLCellDataPB } from '@/services/backend';
import { useEffect, useState } from 'react';
import { CellController } from '$app/stores/effects/database/cell/cell_controller';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { databaseActions, ISelectOptionType } from '$app_reducers/database/slice';

export const useCell = (cellIdentifier: CellIdentifier, cellCache: CellCache, fieldController: FieldController) => {
  const [data, setData] = useState<DateCellDataPB | URLCellDataPB | SelectOptionCellDataPB | string | undefined>();
  const [cellController, setCellController] = useState<CellController<any, any>>();
  const databaseStore = useAppSelector((state) => state.database);
  const dispatch = useAppDispatch();

  useEffect(() => {
    if (!cellIdentifier || !cellCache || !fieldController) return;
    const builder = new CellControllerBuilder(cellIdentifier, cellCache, fieldController);
    const c = builder.build();
    setCellController(c);

    c.subscribeChanged({
      onCellChanged: (cellData) => {
        if (cellData.some) {
          const value = cellData.val;
          setData(value);

          // update redux store for database field if there are new select options
          if (
            value instanceof SelectOptionCellDataPB &&
            (databaseStore.fields[cellIdentifier.fieldId].fieldOptions as ISelectOptionType).selectOptions.length !==
              value.options.length
          ) {
            const field = { ...databaseStore.fields[cellIdentifier.fieldId] };
            const selectOptions = value.options.map((option) => ({
              selectOptionId: option.id,
              title: option.name,
              color: option.color,
            }));

            dispatch(
              databaseActions.updateField({
                field: {
                  ...field,
                  fieldOptions: {
                    ...field.fieldOptions,
                    selectOptions: selectOptions,
                  },
                },
              })
            );
          }
        }
      },
    });

    void (async () => {
      try {
        const cellData = await c.getCellData();
        if (cellData.some) {
          setData(cellData.unwrap());
        }
      } catch (e) {
        // mute for now
      }
    })();

    return () => {
      void c.dispose();
    };
  }, [cellIdentifier, cellCache, fieldController]);

  return {
    cellController,
    data,
  };
};
