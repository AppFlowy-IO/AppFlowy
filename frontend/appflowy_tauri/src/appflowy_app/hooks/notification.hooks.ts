/* eslint-disable no-redeclare */
/* eslint-disable @typescript-eslint/no-explicit-any */
import { useEffect } from 'react';
import { NotificationEnum, NotificationHandler, subscribeNotification } from '$app/application/notification';

export function useNotification<K extends NotificationEnum>(
  notification: K,
  callback: NotificationHandler<K>,
  options: { id?: string }
): void {
  const { id } = options;

  useEffect(() => {
    const unsubscribePromise = subscribeNotification(notification, callback, { id });

    return () => {
      void unsubscribePromise.then((fn) => fn());
    };
  }, [callback, id, notification]);
}
