import { CellIdentifier } from '@/appflowy_app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '@/appflowy_app/stores/effects/database/cell/cell_cache';
import { FieldController } from '@/appflowy_app/stores/effects/database/field/field_controller';
import { FieldType } from '@/services/backend';
import GridSingleSelectOptions from './GridSingleSelectOptions';
import GridTextCell from './GridTextCell';
import { GridCheckBox } from './GridCheckBox';
import { GridDate } from './GridDate';
import { GridUrl } from './GridUrl';
import { GridNumberCell } from './GridNumberCell';

export const GridCell = ({
  cellIdentifier,
  cellCache,
  fieldController,
  width,
}: {
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  width?: number;
}) => {
  return (
    <div style={{ width }}>
      {cellIdentifier.fieldType === FieldType.MultiSelect ||
      cellIdentifier.fieldType === FieldType.Checklist ||
      cellIdentifier.fieldType === FieldType.SingleSelect ? (
        <GridSingleSelectOptions
          cellIdentifier={cellIdentifier}
          cellCache={cellCache}
          fieldController={fieldController}
        />
      ) : cellIdentifier.fieldType === FieldType.Checkbox ? (
        <GridCheckBox cellIdentifier={cellIdentifier} cellCache={cellCache} fieldController={fieldController} />
      ) : cellIdentifier.fieldType === FieldType.DateTime ? (
        <GridDate cellIdentifier={cellIdentifier} cellCache={cellCache} fieldController={fieldController}></GridDate>
      ) : cellIdentifier.fieldType === FieldType.URL ? (
        <GridUrl cellIdentifier={cellIdentifier} cellCache={cellCache} fieldController={fieldController}></GridUrl>
      ) : cellIdentifier.fieldType === FieldType.Number ? (
        <GridNumberCell cellIdentifier={cellIdentifier} cellCache={cellCache} fieldController={fieldController} />
      ) : (
        <GridTextCell cellIdentifier={cellIdentifier} cellCache={cellCache} fieldController={fieldController} />
      )}
    </div>
  );
};
