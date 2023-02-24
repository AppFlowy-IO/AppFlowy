import { Err, Ok, Result } from 'ts-results';
import { DatabaseNotification } from '../../../../../services/backend';
import { DatabaseFieldChangesetPB } from '../../../../../services/backend/models/flowy-database/field_entities';
import { FlowyError } from '../../../../../services/backend/models/flowy-error';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';

type UpdateFieldNotifiedValue = Result<DatabaseFieldChangesetPB, FlowyError>;
export type DatabaseNotificationCallback = (value: UpdateFieldNotifiedValue) => void;

export class DatabaseFieldObserver {
  _notifier?: ChangeNotifier<UpdateFieldNotifiedValue>;
  _listener?: DatabaseNotificationObserver;

  constructor(public readonly databaseId: string) {}

  subscribe = (callbacks: { onFieldsChanged: DatabaseNotificationCallback }) => {
    this._notifier = new ChangeNotifier();
    this._notifier?.observer.subscribe(callbacks.onFieldsChanged);

    this._listener = new DatabaseNotificationObserver({
      viewId: this.databaseId,
      parserHandler: (notification, payload) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateFields:
            this._notifier?.notify(Ok(DatabaseFieldChangesetPB.deserializeBinary(payload)));
            return;
          default:
            break;
        }
      },
      onError: (error) => this._notifier?.notify(Err(error)),
    });
    return undefined;
  };

  unsubscribe = async () => {
    this._notifier?.unsubscribe();
    await this._listener?.stop();
  };
}
