import React from 'react';
import {
  FolderEventReadCurrentWorkspace,
  ViewLayoutTypePB,
  WorkspaceSettingPB,
} from '../../../services/backend/events/flowy-folder';
import { AppBackendService } from '../../stores/effects/folder/app/backend_service';
import { DatabaseController } from '../../stores/effects/database/controller';
import { Log } from '../../utils/log';
import { RowController } from '../../stores/effects/database/row/controller';
import { CellControllerBuilder } from '../../stores/effects/database/cell/controller_builder';

export const TestCreateGridButton = () => {
  async function createGrid() {
    const workspaceSetting: WorkspaceSettingPB = await FolderEventReadCurrentWorkspace().then((result) =>
      result.unwrap()
    );
    const app = workspaceSetting.workspace.apps.items[0];
    const appService = new AppBackendService(app.id);
    const view = await appService.createView({ name: 'New Grid', layoutType: ViewLayoutTypePB.Grid });
    const databaseController = new DatabaseController(view.id);

    databaseController.subscribe({
      onViewChanged: (databasePB) => {
        Log.debug('Did receive database:' + databasePB);
      },
      onRowsChanged: async (rows) => {
        if (rows.length === 0) {
          return;
        }

        const rowInfo = rows[0];
        const rowCache = databaseController.databaseViewCache.getRowCache();
        const cellCache = rowCache.getCellCache();
        const fieldController = databaseController.fieldController;
        const rowController = new RowController(rowInfo, fieldController, rowCache);
        const cellByFieldId = await rowController.loadCells();

        // Initial each cell controller
        for (const cellIdentifier of cellByFieldId.values()) {
          const builder = new CellControllerBuilder(cellIdentifier, cellCache, fieldController);
          const cellController = builder.build();
          cellController.subscribeChanged({
            onCellChanged: (value) => {
              Log.debug(value);
            },
          });

          const cellData = cellController.getCellData();
          Log.debug(cellData);
        }
      },
      onFieldsChanged: (fields) => {
        console.log(fields);
      },
    });

    // Open the grid
    await databaseController.open().then((result) => result.unwrap());
    return;
  }

  return (
    <React.Fragment>
      <div>
        <button className='rounded-md bg-gray-700 p-4' type='button' onClick={() => createGrid()}>
          Create a grid
        </button>
      </div>
    </React.Fragment>
  );
};
