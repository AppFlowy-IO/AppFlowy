import { Err, Ok, Result } from 'ts-results';
import { DatabaseNotification } from '../../../../../services/backend';
import { DatabaseFieldChangesetPB } from '../../../../../services/backend/models/flowy-database/field_entities';
import { FlowyError } from '../../../../../services/backend/models/flowy-error';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';

type UpdateFieldNotifiedValue = Result<DatabaseFieldChangesetPB, FlowyError>;
export type DatabaseNotificationCallback = (value: UpdateFieldNotifiedValue) => void;

export class DatabaseFieldObserver {
  private _notifier?: ChangeNotifier<UpdateFieldNotifiedValue>;
  private _listener?: DatabaseNotificationObserver;

  constructor(public readonly viewId: string) {}

  subscribe = (callbacks: { onFieldsChanged: DatabaseNotificationCallback }) => {
    this._notifier = new ChangeNotifier();
    this._notifier?.observer.subscribe(callbacks.onFieldsChanged);

    this._listener = new DatabaseNotificationObserver({
      viewId: this.viewId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateFields:
            if (result.ok) {
              this._notifier?.notify(Ok(DatabaseFieldChangesetPB.deserializeBinary(result.val)));
            } else {
              this._notifier?.notify(result);
            }
            return;
          default:
            break;
        }
      },
    });
    return undefined;
  };

  unsubscribe = async () => {
    this._notifier?.unsubscribe();
    await this._listener?.stop();
  };
}
