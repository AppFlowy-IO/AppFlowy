import { OnNotificationError, AFNotificationObserver } from '@/services/backend/notifications';
import { FolderNotificationParser } from './parser';
import { FlowyError, FolderNotification } from '@/services/backend';
import { Result } from 'ts-results';

export type ParserHandler = (notification: FolderNotification, payload: Result<Uint8Array, FlowyError>) => void;

export class FolderNotificationObserver extends AFNotificationObserver<FolderNotification> {
  constructor(params: { viewId?: string; parserHandler: ParserHandler; onError?: OnNotificationError }) {
    const parser = new FolderNotificationParser({
      callback: params.parserHandler,
      id: params.viewId,
    });
    super(parser);
  }
}
