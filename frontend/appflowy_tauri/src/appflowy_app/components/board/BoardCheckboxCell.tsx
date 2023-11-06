import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { useCell } from '$app/components/_shared/database-hooks/useCell';

export const BoardCheckboxCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
}) => {
  const { data } = useCell(cellIdentifier, cellCache, fieldController);

  return (
    <i className={'h-5 w-5'}>
      {data === 'Yes' ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
    </i>
  );
};
