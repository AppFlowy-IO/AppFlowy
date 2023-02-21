import { Err, Ok, Result } from 'ts-results';
import { ChangeNotifier } from '../../../../utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';
import { FlowyError } from '../../../../../services/backend/models/flowy-error';
import { DatabaseNotification } from '../../../../../services/backend';

type UpdateCellNotifiedValue = Result<void, FlowyError>;

export type CellListenerCallback = (value: UpdateCellNotifiedValue) => void;

export class CellObserver {
  _notifier?: ChangeNotifier<UpdateCellNotifiedValue>;
  _listener?: DatabaseNotificationObserver;
  constructor(public readonly rowId: string, public readonly fieldId: string) {}

  subscribe = (callbacks: { onCellChanged: CellListenerCallback }) => {
    this._notifier = new ChangeNotifier();
    this._notifier?.observer.subscribe(callbacks.onCellChanged);

    this._listener = new DatabaseNotificationObserver({
      viewId: this.rowId + ':' + this.fieldId,
      parserHandler: (notification) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateCell:
            this._notifier?.notify(Ok.EMPTY);
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
