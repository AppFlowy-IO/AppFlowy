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
        // Rendering rows
        Log.debug('Did receive rows:' + rows);
        const rowInfo = rows[0];
        const rowController = new RowController(
          rowInfo,
          databaseController.fieldController,
          databaseController.databaseViewCache.getRowCache()
        );

        const a = await rowController.loadCells();
      },
      onFieldsChanged: (fields) => {
        // Rendering fields
        Log.debug('Did receive fields:' + fields);
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
