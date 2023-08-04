import { FolderNotification } from '@/services/backend';
import { WorkspaceNotificationObserver } from '$app/stores/effects/workspace/notifications/observer';

export class WorkspaceObserver {
  private listener?: WorkspaceNotificationObserver;
  constructor() {
    //
  }

  subscribeWorkspaces = async (callback: (payload: Uint8Array) => void) => {
    this.listener = new WorkspaceNotificationObserver({
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidCreateWorkspace:
            if (!result.ok) break;
            callback(result.val);
            break;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  subscribeWorkspace = async (
    workspaceId: string,
    callbacks: {
      didUpdateChildViews?: (payload: Uint8Array) => void;
      didUpdateWorkspace?: (payload: Uint8Array) => void;
      didDeleteWorkspace?: (payload: Uint8Array) => void;
    }
  ) => {
    this.listener = new WorkspaceNotificationObserver({
      id: workspaceId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateWorkspaceViews:
            if (!result.ok) break;
            callbacks.didUpdateWorkspace?.(result.val);
            break;
          case FolderNotification.DidUpdateChildViews:
            if (!result.ok) break;
            callbacks.didUpdateChildViews?.(result.val);
            break;
          // case FolderNotification.DidDeleteWorkspace:
          //   if (!result.ok) break;
          //   callbacks.didDeleteWorkspace(result.val);
          //   break;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  subscribeView = async (
    viewId: string,
    callbacks: {
      didUpdateChildViews?: (payload: Uint8Array) => void;
      didUpdateView?: (payload: Uint8Array) => void;
    }
  ) => {
    this.listener = new WorkspaceNotificationObserver({
      id: viewId,
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateChildViews:
            if (!result.ok) break;
            callbacks.didUpdateChildViews?.(result.val);
            break;
          case FolderNotification.DidUpdateView:
            if (!result.ok) break;
            callbacks.didUpdateView?.(result.val);
            break;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  subscribeTrash = async (callbacks: { didUpdateTrash: (payload: Uint8Array) => void }) => {
    this.listener = new WorkspaceNotificationObserver({
      parserHandler: (notification, result) => {
        switch (notification) {
          case FolderNotification.DidUpdateTrash:
            if (!result.ok) break;
            callbacks.didUpdateTrash(result.val);
            break;
          default:
            break;
        }
      },
    });
    await this.listener.start();
  };

  unsubscribe = async () => {
    await this.listener?.stop();
  };
}
