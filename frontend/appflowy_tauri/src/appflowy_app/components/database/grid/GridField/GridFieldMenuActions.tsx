import { Grid, MenuItem } from '@mui/material';
import { t } from 'i18next';

import { ReactComponent as HideSvg } from '$app/assets/hide.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as LeftSvg } from '$app/assets/left.svg';
import { ReactComponent as RightSvg } from '$app/assets/right.svg';

enum FieldAction {
  Hide = 'hide',
  Duplicate = 'duplicate',
  Delete = 'delete',
  InsertLeft = 'insertLeft',
  InsertRight = 'insertRight',
}

const FieldActionSvgMap = {
  [FieldAction.Hide]: HideSvg,
  [FieldAction.Duplicate]: CopySvg,
  [FieldAction.Delete]: DeleteSvg,
  [FieldAction.InsertLeft]: LeftSvg,
  [FieldAction.InsertRight]: RightSvg,
};

const TwoColumnActions: FieldAction[][] = [
  [FieldAction.Hide, FieldAction.Duplicate, FieldAction.Delete],
  [FieldAction.InsertLeft, FieldAction.InsertRight],
];

export const GridFieldMenuActions = () => {
  return (
    <Grid container spacing={2}>
      {TwoColumnActions.map((column, index) => (
        <Grid key={index} item xs={6}>
          {column.map(action => {
            const ActionSvg = FieldActionSvgMap[action];

            return (
              <MenuItem key={action} dense>
                <ActionSvg className="mr-2 text-base" />
                {t(`grid.field.${action}`)}
              </MenuItem>
            );
          })}
        </Grid>
      ))}
    </Grid>
  );
};