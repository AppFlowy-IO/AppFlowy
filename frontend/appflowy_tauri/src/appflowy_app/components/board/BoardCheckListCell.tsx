import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { useEffect, useState } from 'react';
import { ISelectOptionType } from '$app_reducers/database/slice';
import { SelectOptionCellDataPB } from '@/services/backend';
import { useAppSelector } from '$app/stores/store';
import { CheckListProgress } from '$app/components/_shared/CheckListProgress';

export const BoardCheckListCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data } = useCell(cellIdentifier, cellCache, fieldController);

  const databaseStore = useAppSelector((state) => state.database);
  const [allOptionsCount, setAllOptionsCount] = useState(0);
  const [selectedOptionsCount, setSelectedOptionsCount] = useState(0);

  useEffect(() => {
    setAllOptionsCount(
      (databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as ISelectOptionType)?.selectOptions?.length ?? 0
    );
  }, [databaseStore, cellIdentifier]);

  useEffect(() => {
    setSelectedOptionsCount((data as SelectOptionCellDataPB)?.select_options?.length ?? 0);
  }, [data]);

  return <CheckListProgress completed={selectedOptionsCount} max={allOptionsCount} />;
};
