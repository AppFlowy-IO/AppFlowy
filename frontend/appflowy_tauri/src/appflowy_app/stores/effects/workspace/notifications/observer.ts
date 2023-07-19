import { OnNotificationError, AFNotificationObserver } from '@/services/backend/notifications';
import { FlowyError, FolderNotification } from '@/services/backend';
import { Result } from 'ts-results';
import { WorkspaceNotificationParser } from './parser';

export type ParserHandler = (notification: FolderNotification, payload: Result<Uint8Array, FlowyError>) => void;

export class WorkspaceNotificationObserver extends AFNotificationObserver<FolderNotification> {
  constructor(params: { id?: string; parserHandler: ParserHandler; onError?: OnNotificationError }) {
    const parser = new WorkspaceNotificationParser({
      callback: params.parserHandler,
      id: params.id,
    });

    super(parser);
  }
}
