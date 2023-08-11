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
};

type NotificationMap = typeof NotificationPBMap;

type NotificationEnum = keyof NotificationMap;

type NotificationHandler<T> = (result: Result<T, FlowyError>) => void;

export function subscribeNotification<K extends NotificationEnum>(id: string | undefined, notification: K, callback: NotificationHandler<InstanceType<NotificationMap[K]>>): Promise<() => void>;
export function subscribeNotification(id: string | undefined, notification: number, callback: NotificationHandler<unknown>): Promise<() => void> {
  return listen<ReturnType<typeof SubscribeObject.prototype.toObject>>('af-notification', event => {
    const subject = SubscribeObject.fromObject(event.payload);

    if (id && id !== subject.id) {
      return;
    }

    const { ty } = subject;

    if (ty === null || ty !== notification) {
      return;
    }

    if (subject.has_error) {
      const error = FlowyError.deserializeBinary(subject.error);

      callback(Err(error));
    } else {
      const { payload } = subject;
      const pb = NotificationPBMap[ty as keyof NotificationMap];

      callback(Ok(pb ? pb.deserializeBinary(payload) : payload));
    }
  });
}

export function useNotification<K extends NotificationEnum>(id: string | undefined, notification: K, callback: NotificationHandler<NotificationMap[K]>): void;
export function useNotification(id: string | undefined, notification: number, callback: NotificationHandler<unknown>): void {
  useEffect(() => {
    const unListenPromise = subscribeNotification(id, notification, callback);

    return () => {
      void unListenPromise.then(fn => fn());
    };
  }, [id, notification, callback]);
}
