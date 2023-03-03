import { useCell } from '../_shared/database-hooks/useCell';
import { CellIdentifier } from '../../stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '../../stores/effects/database/cell/cell_cache';
import { FieldController } from '../../stores/effects/database/field/field_controller';
import {useEffect} from "react";

export const BoardCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { loadCell, data } = useCell(cellIdentifier, cellCache, fieldController);
  useEffect(() => {
    void (async () => {
      await loadCell()
    })();
  }, [])
  return <div>{data}</div>;
};
