import { listen } from '@tauri-apps/api/event';
import { SubscribeObject } from '@/services/backend/models/flowy-notification';
import {
  DatabaseFieldChangesetPB,
  DatabaseNotification,
  DocEventPB,
  DocumentNotification,
  FieldPB,
  FieldSettingsPB,
  FilterChangesetNotificationPB,
  GroupChangesPB,
  GroupRowsNotificationPB,
  ReorderAllRowsPB,
  ReorderSingleRowPB,
  RowsChangePB,
  RowsVisibilityChangePB,
  SortChangesetNotificationPB,
  UserNotification,
  UserProfilePB,
  FolderNotification,
  RepeatedViewPB,
  ViewPB,
  RepeatedTrashPB,
  ChildViewUpdatePB,
  WorkspacePB,
} from '@/services/backend';
import { AsyncQueue } from '$app/utils/async_queue';

const Notification = {
  [DatabaseNotification.DidUpdateViewRowsVisibility]: RowsVisibilityChangePB,
  [DatabaseNotification.DidUpdateViewRows]: RowsChangePB,
  [DatabaseNotification.DidReorderRows]: ReorderAllRowsPB,
  [DatabaseNotification.DidReorderSingleRow]: ReorderSingleRowPB,
  [DatabaseNotification.DidUpdateFields]: DatabaseFieldChangesetPB,
  [DatabaseNotification.DidGroupByField]: GroupChangesPB,
  [DatabaseNotification.DidUpdateNumOfGroups]: GroupChangesPB,
  [DatabaseNotification.DidUpdateGroupRow]: GroupRowsNotificationPB,
  [DatabaseNotification.DidUpdateField]: FieldPB,
  [DatabaseNotification.DidUpdateCell]: null,
  [DatabaseNotification.DidUpdateSort]: SortChangesetNotificationPB,
  [DatabaseNotification.DidUpdateFieldSettings]: FieldSettingsPB,
  [DatabaseNotification.DidUpdateFilter]: FilterChangesetNotificationPB,
  [DocumentNotification.DidReceiveUpdate]: DocEventPB,
  [FolderNotification.DidUpdateWorkspace]: WorkspacePB,
  [FolderNotification.DidUpdateWorkspaceViews]: RepeatedViewPB,
  [FolderNotification.DidUpdateView]: ViewPB,
  [FolderNotification.DidUpdateChildViews]: ChildViewUpdatePB,
  [FolderNotification.DidUpdateTrash]: RepeatedTrashPB,
  [UserNotification.DidUpdateUserProfile]: UserProfilePB,
};

type NotificationMap = typeof Notification;
export type NotificationEnum = keyof NotificationMap;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type NullableInstanceType<K extends (abstract new (...args: any) => any) | null> = K extends abstract new (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ...args: any
) => // eslint-disable-next-line @typescript-eslint/no-explicit-any
any
  ? InstanceType<K>
  : void;
export type NotificationHandler<K extends NotificationEnum> = (
  result: NullableInstanceType<NotificationMap[K]>
) => void | Promise<void>;

/**
 * Subscribes to a set of notifications.
 *
 * This function subscribes to notifications defined by the `NotificationEnum` and
 * calls the appropriate `NotificationHandler` when each type of notification is received.
 *
 * @param {Object} callbacks - An object containing handlers for various notification types.
 * Each key is a `NotificationEnum` value, and the corresponding value is a `NotificationHandler` function.
 *
 * @param {Object} [options] - Optional settings for the subscription.
 * @param {string} [options.id] - An optional ID. If provided, only notifications with a matching ID will be processed.
 *
 * @returns {Promise<() => void>} A Promise that resolves to an unsubscribe function.
 *
 * @example
 * subscribeNotifications({
 *   [DatabaseNotification.DidUpdateField]: (result) => {
 *     if (result.err) {
 *       // process error
 *       return;
 *     }
 *
 *     console.log(result.val); // result.val is FieldPB
 *   },
 *   [DatabaseNotification.DidReorderRows]: (result) => {
 *     if (result.err) {
 *       // process error
 *       return;
 *     }
 *
 *     console.log(result.val); // result.val is ReorderAllRowsPB
 *   },
 * }, { id: '123' })
 * .then(unsubscribe => {
 *   // Do something
 *   // ...
 *   // To unsubscribe, call `unsubscribe()`
 * });
 *
 * @throws {Error} Throws an error if unable to subscribe.
 */
export function subscribeNotifications(
  callbacks: {
    [K in NotificationEnum]?: NotificationHandler<K>;
  },
  options?: { id?: string | number }
): Promise<() => void> {
  const handler = async (subject: SubscribeObject) => {
    const { id, ty } = subject;

    if (options?.id !== undefined && id !== options.id) {
      return;
    }

    const notification = ty as NotificationEnum;
    const pb = Notification[notification];
    const callback = callbacks[notification] as NotificationHandler<NotificationEnum>;

    if (pb === undefined || !callback) {
      return;
    }

    if (subject.has_error) {
      // const error = FlowyError.deserialize(subject.error);
      return;
    } else {
      const { payload } = subject;

      if (pb) {
        await callback(pb.deserialize(payload));
      } else {
        await callback();
      }
    }
  };

  const queue = new AsyncQueue(handler);

  return listen<ReturnType<typeof SubscribeObject.prototype.toObject>>('af-notification', (event) => {
    const subject = SubscribeObject.fromObject(event.payload);

    queue.enqueue(subject);
  });
}

export function subscribeNotification<K extends NotificationEnum>(
  notification: K,
  callback: NotificationHandler<K>,
  options?: { id?: string }
): Promise<() => void> {
  return subscribeNotifications({ [notification]: callback }, options);
}
