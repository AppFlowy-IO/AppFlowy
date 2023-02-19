import { DatabaseNotification } from '../../../../../services/backend/models/flowy-database/notification';
import { OnNotificationError } from '../../../../../services/backend/notifications';
import { AFNotificationObserver } from '../../../../../services/backend/notifications/observer';
import { DatabaseNotificationParser } from './parser';

export type ParserHandler = (notification: DatabaseNotification, payload: Uint8Array) => void;

export class DatabaseNotificationObserver extends AFNotificationObserver<DatabaseNotification> {
  constructor(params: { viewId?: string; parserHandler: ParserHandler; onError?: OnNotificationError }) {
    const parser = new DatabaseNotificationParser({
      callback: params.parserHandler,
      id: params.viewId,
      onError: params.onError,
    });
    super(parser);
  }
}
