import { DatabaseNotification } from '../../../../services/backend/models/flowy-database/notification';
import { OnNotificationError } from '../../../../services/backend/notifications';
import { AFNotificationListener } from '../../../../services/backend/notifications/listener';
import { DatabaseNotificationParser } from './parser';

export type ParserHandler = (notification: DatabaseNotification, payload: Uint8Array) => void;

export class DatabaseNotificationListener extends AFNotificationListener<DatabaseNotification> {
  constructor(params: { viewId?: string; parserHandler: ParserHandler; onError?: OnNotificationError }) {
    const parser = new DatabaseNotificationParser({
      callback: params.parserHandler,
      id: params.viewId,
      onError: params.onError,
    });
    super(parser);
  }
}
