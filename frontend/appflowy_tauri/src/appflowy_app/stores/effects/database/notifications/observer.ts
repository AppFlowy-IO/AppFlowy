import { DatabaseNotification } from '../../../../../services/backend';
import { AFNotificationObserver } from '../../../../../services/backend/notifications';
import { DatabaseNotificationParser } from './parser';
import { FlowyError } from '../../../../../services/backend';
import { Result } from 'ts-results';

export type ParserHandler = (notification: DatabaseNotification, result: Result<Uint8Array, FlowyError>) => void;

export class DatabaseNotificationObserver extends AFNotificationObserver<DatabaseNotification> {
  constructor(params: { viewId?: string; parserHandler: ParserHandler }) {
    const parser = new DatabaseNotificationParser({
      callback: params.parserHandler,
      id: params.viewId,
    });
    super(parser);
  }
}
