import { GridNotification } from '../../../../../services/backend';
import { NotificationParser, OnNotificationError } from '../../../../../services/backend/notifications/parser';

declare type GridNotificationCallback = (ty: GridNotification, payload: Uint8Array) => void;

export class GridNotificationParser extends NotificationParser<GridNotification> {
  constructor(params: { id?: String; callback: GridNotificationCallback; onError?: OnNotificationError }) {
    super(
      params.callback,
      (ty) => {
        let notification = GridNotification[ty];
        if (isGridNotification(notification)) {
          return GridNotification[notification];
        } else {
          return GridNotification.Unknown;
        }
      },
      params.id,
      params.onError
    );
  }
}

const isGridNotification = (notification: string): notification is keyof typeof GridNotification => {
  return Object.values(GridNotification).indexOf(notification) !== -1;
};
