import { OnNotificationError, AFNotificationObserver } from '@/services/backend/notifications';
import { DocumentNotificationParser } from './parser';
import { FlowyError, DocumentNotification } from '@/services/backend';
import { Result } from 'ts-results';

export type ParserHandler = (notification: DocumentNotification, payload: Result<Uint8Array, FlowyError>) => void;

export class DocumentNotificationObserver extends AFNotificationObserver<DocumentNotification> {
  constructor(params: { viewId?: string; parserHandler: ParserHandler; onError?: OnNotificationError }) {
    const parser = new DocumentNotificationParser({
      callback: params.parserHandler,
      id: params.viewId,
    });
    super(parser);
  }
}
