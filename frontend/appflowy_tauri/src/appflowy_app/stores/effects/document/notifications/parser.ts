import { NotificationParser, OnNotificationError } from '@/services/backend/notifications';
import { FlowyError, DocumentNotification } from '@/services/backend';
import { Result } from 'ts-results';

declare type DocumentNotificationCallback = (ty: DocumentNotification, payload: Result<Uint8Array, FlowyError>) => void;

export class DocumentNotificationParser extends NotificationParser<DocumentNotification> {
  constructor(params: { id?: string; callback: DocumentNotificationCallback; onError?: OnNotificationError }) {
    super(
      params.callback,
      (ty) => {
        const notification = DocumentNotification[ty];
        if (isDocumentNotification(notification)) {
          return DocumentNotification[notification];
        } else {
          return DocumentNotification.Unknown;
        }
      },
      params.id
    );
  }
}

const isDocumentNotification = (notification: string): notification is keyof typeof DocumentNotification => {
  return Object.values(DocumentNotification).indexOf(notification) !== -1;
};
