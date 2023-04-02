import { ChangeNotifier } from '$app/utils/change_notifier';
import { Ok, Result } from 'ts-results';
import { DatabaseNotification, FlowyError, GroupChangesetPB, GroupPB } from '@/services/backend';
import { DatabaseNotificationObserver } from '../notifications/observer';

export type GroupByFieldCallback = (value: Result<GroupPB[], FlowyError>) => void;
export type GroupChangesetSubscribeCallback = (value: Result<GroupChangesetPB, FlowyError>) => void;

export class DatabaseGroupObserver {
  private groupByNotifier?: ChangeNotifier<Result<GroupPB[], FlowyError>>;
  private groupChangesetNotifier?: ChangeNotifier<Result<GroupChangesetPB, FlowyError>>;
  private listener?: DatabaseNotificationObserver;

  constructor(public readonly viewId: string) {}

  subscribe = async (callbacks: {
    onGroupBy: GroupByFieldCallback;
    onGroupChangeset: GroupChangesetSubscribeCallback;
  }) => {
    this.groupByNotifier = new ChangeNotifier();
    this.groupByNotifier?.observer.subscribe(callbacks.onGroupBy);

    this.groupChangesetNotifier = new ChangeNotifier();
    this.groupChangesetNotifier?.observer.subscribe(callbacks.onGroupChangeset);

    this.listener = new DatabaseNotificationObserver({
      id: this.viewId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case DatabaseNotification.DidGroupByField:
            if (result.ok) {
              this.groupByNotifier?.notify(Ok(GroupChangesetPB.deserializeBinary(result.val).initial_groups));
            } else {
              this.groupByNotifier?.notify(result);
            }
            break;
          case DatabaseNotification.DidUpdateGroups:
            if (result.ok) {
              this.groupChangesetNotifier?.notify(Ok(GroupChangesetPB.deserializeBinary(result.val)));
            } else {
              this.groupChangesetNotifier?.notify(result);
            }
            break;
          default:
            break;
        }
      },
    });

    await this.listener.start();
  };

  unsubscribe = async () => {
    this.groupByNotifier?.unsubscribe();
    this.groupChangesetNotifier?.unsubscribe();
    await this.listener?.stop();
  };
}
