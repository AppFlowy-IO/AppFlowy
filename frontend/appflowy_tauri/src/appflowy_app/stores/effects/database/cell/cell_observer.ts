import { Ok, Result } from 'ts-results';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { DatabaseNotificationObserver } from '../notifications/observer';
import { DatabaseNotification, FlowyError } from '@/services/backend';

type UpdateCellNotifiedValue = Result<void, FlowyError>;

export type CellChangedCallback = (value: UpdateCellNotifiedValue) => void;

export class CellObserver {
  private notifier?: ChangeNotifier<UpdateCellNotifiedValue>;
  private listener?: DatabaseNotificationObserver;

  constructor(public readonly rowId: string, public readonly fieldId: string) {}

  subscribe = async (callbacks: { onCellChanged: CellChangedCallback }) => {
    this.notifier = new ChangeNotifier();
    this.notifier?.observer.subscribe(callbacks.onCellChanged);

    this.listener = new DatabaseNotificationObserver({
      // The rowId combine with fieldId can identifier the cell.
      // This format rowId:fieldId is also defined in the backend,
      // so don't change this.
      id: this.rowId + ':' + this.fieldId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidUpdateCell:
            if (result.ok) {
              this.notifier?.notify(Ok.EMPTY);
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
