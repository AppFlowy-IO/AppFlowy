import { OnNotificationError } from '../../../../../services/backend/notifications';
import { AFNotificationObserver } from '../../../../../services/backend/notifications/observer';
import { FolderNotificationParser } from './parser';
import { FolderNotification } from '../../../../../services/backend/models/flowy-folder/notification';

export type ParserHandler = (notification: FolderNotification, payload: Uint8Array) => void;

export class FolderNotificationObserver extends AFNotificationObserver<FolderNotification> {
  constructor(params: { viewId?: string; parserHandler: ParserHandler; onError?: OnNotificationError }) {
    const parser = new FolderNotificationParser({
      callback: params.parserHandler,
      id: params.viewId,
      onError: params.onError,
    });
    super(parser);
  }
}
