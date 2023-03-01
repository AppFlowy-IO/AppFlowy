import { Ok, Result } from 'ts-results';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';
import { DatabaseNotification, FlowyError } from '../../../../../services/backend';

type UpdateCellNotifiedValue = Result<void, FlowyError>;

export type CellChangedCallback = (value: UpdateCellNotifiedValue) => void;

export class CellObserver {
  private _notifier?: ChangeNotifier<UpdateCellNotifiedValue>;
  private _listener?: DatabaseNotificationObserver;

  constructor(public readonly rowId: string, public readonly fieldId: string) {}

  subscribe = async (callbacks: { onCellChanged: CellChangedCallback }) => {
    this._notifier = new ChangeNotifier();
    this._notifier?.observer.subscribe(callbacks.onCellChanged);

    this._listener = new DatabaseNotificationObserver({
      viewId: this.rowId + ':' + this.fieldId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateCell:
            if (result.ok) {
              this._notifier?.notify(Ok.EMPTY);
            } else {
              this._notifier?.notify(result);
            }
            return;
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
