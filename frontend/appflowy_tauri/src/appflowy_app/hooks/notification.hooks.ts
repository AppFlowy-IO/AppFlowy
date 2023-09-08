/* eslint-disable no-redeclare */
import { useEffect } from 'react';
import { listen } from '@tauri-apps/api/event';
import { Ok, Err, Result } from 'ts-results';
import { SubscribeObject } from '@/services/backend/models/flowy-notification';
import { FlowyError } from '@/services/backend/models/flowy-error';
import {
  DatabaseFieldChangesetPB,
  DatabaseNotification,
  FieldPB,
  GroupChangesPB,
  GroupRowsNotificationPB,
  ReorderAllRowsPB,
  ReorderSingleRowPB,
  RowsChangePB,
  RowsVisibilityChangePB,
} from '@/services/backend';

const NotificationPBMap = {
  [DatabaseNotification.DidUpdateViewRowsVisibility]: RowsVisibilityChangePB,
  [DatabaseNotification.DidUpdateViewRows]: RowsChangePB,
  [DatabaseNotification.DidReorderRows]: ReorderAllRowsPB,
  [DatabaseNotification.DidReorderSingleRow]:ReorderSingleRowPB,
  [DatabaseNotification.DidUpdateFields]:DatabaseFieldChangesetPB,
  [DatabaseNotification.DidGroupByField]:GroupChangesPB,
  [DatabaseNotification.DidUpdateNumOfGroups]:GroupChangesPB,
  [DatabaseNotification.DidUpdateGroupRow]: GroupRowsNotificationPB,
  [DatabaseNotification.DidUpdateField]: FieldPB,
  [DatabaseNotification.DidUpdateCell]: null,
};

type NotificationMap = typeof NotificationPBMap;

type NotificationEnum = keyof NotificationMap;

type NullableInstanceType<K extends ((abstract new (...args: any) => any) | null)> = K extends (abstract new (...args: any) => any) ? InstanceType<K> : void;

type NotificationHandler<K extends NotificationEnum> = (result: Result<NullableInstanceType<NotificationMap[K]>, FlowyError>) => void;

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
  options?: { id?: string },
): Promise<() => void> {
  return listen<ReturnType<typeof SubscribeObject.prototype.toObject>>('af-notification', event => {
    const subject = SubscribeObject.fromObject(event.payload);
    const { id, ty } = subject;

    if (options?.id !== undefined && id !== options.id) {
      return;
    }

    const notification = ty as NotificationEnum;
    const pb = NotificationPBMap[notification];
    const callback = callbacks[notification] as NotificationHandler<NotificationEnum>;

    if (pb === undefined || !callback) {
      return;
    }

    if (subject.has_error) {
      const error = FlowyError.deserializeBinary(subject.error);

      callback(Err(error));
    } else {
      const { payload } = subject;

      callback(pb ? Ok(pb.deserializeBinary(payload)) : Ok.EMPTY);
    }
  });
}

export function subscribeNotification<K extends NotificationEnum>(
  notification: K,
  callback: NotificationHandler<K>,
  options?: { id?: string },
): Promise<() => void> {
  return subscribeNotifications({ [notification]: callback }, options);
}

export function useNotification<K extends NotificationEnum>(
  notification: K,
  callback: NotificationHandler<K>,
  options: { id?: string },
): void {
  const { id } = options;

  useEffect(() => {
    const unsubscribePromise = subscribeNotification(notification, callback, { id });

    return () => {
      void unsubscribePromise.then(fn => fn());
    };
  }, [callback, id, notification]);
}
