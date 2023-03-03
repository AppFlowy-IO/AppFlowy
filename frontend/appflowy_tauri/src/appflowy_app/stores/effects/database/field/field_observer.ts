import { Ok, Result } from 'ts-results';
import { DatabaseNotification, DatabaseFieldChangesetPB, FlowyError, FieldPB } from '../../../../../services/backend';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';

type UpdateFieldNotifiedValue = Result<DatabaseFieldChangesetPB, FlowyError>;
export type DatabaseNotificationCallback = (value: UpdateFieldNotifiedValue) => void;

export class DatabaseFieldChangesetObserver {
  private notifier?: ChangeNotifier<UpdateFieldNotifiedValue>;
  private listener?: DatabaseNotificationObserver;

  constructor(public readonly viewId: string) {}

  subscribe = async (callbacks: { onFieldsChanged: DatabaseNotificationCallback }) => {
    this.notifier = new ChangeNotifier();
    this.notifier?.observer.subscribe(callbacks.onFieldsChanged);

    this.listener = new DatabaseNotificationObserver({
      id: this.viewId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateFields:
            if (result.ok) {
              this.notifier?.notify(Ok(DatabaseFieldChangesetPB.deserializeBinary(result.val)));
            } else {
              this.notifier?.notify(result);
            }
            return;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  unsubscribe = async () => {
    this.notifier?.unsubscribe();
    await this.listener?.stop();
  };
}

type FieldNotifiedValue = Result<FieldPB, FlowyError>;
export type FieldNotificationCallback = (value: FieldNotifiedValue) => void;

export class DatabaseFieldObserver {
  private _notifier?: ChangeNotifier<FieldNotifiedValue>;
  private _listener?: DatabaseNotificationObserver;

  constructor(public readonly fieldId: string) {}

  subscribe = async (callbacks: { onFieldChanged: FieldNotificationCallback }) => {
    this._notifier = new ChangeNotifier();
    this._notifier?.observer.subscribe(callbacks.onFieldChanged);

    this._listener = new DatabaseNotificationObserver({
      id: this.fieldId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateField:
            if (result.ok) {
              this._notifier?.notify(Ok(FieldPB.deserializeBinary(result.val)));
            } else {
              this._notifier?.notify(result);
            }
            break;
          default:
            break;
        }
      },
    });
    await this._listener.start();
  };

  unsubscribe = async () => {
    this._notifier?.unsubscribe();
    await this._listener?.stop();
  };
}
