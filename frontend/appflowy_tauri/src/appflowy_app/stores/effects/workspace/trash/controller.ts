import { TrashBackendService } from '$app/stores/effects/workspace/trash/bd_svc';
import { WorkspaceObserver } from '$app/stores/effects/workspace/workspace_observer';
import { RepeatedTrashPB, TrashPB } from '@/services/backend';

export class TrashController {
  private readonly observer: WorkspaceObserver = new WorkspaceObserver();

  private readonly backendService: TrashBackendService = new TrashBackendService();

  subscribe = async (callbacks: { onTrashChanged?: (trash: TrashPB[]) => void }) => {
    const didUpdateTrash = (payload: Uint8Array) => {
      const res = RepeatedTrashPB.deserializeBinary(payload);

      callbacks.onTrashChanged?.(res.items);
    };

    await this.observer.subscribeTrash({
      didUpdateTrash,
    });
  };

  dispose = async () => {
    await this.observer.unsubscribe();
  };
  getTrash = async () => {
    const res = await this.backendService.getTrash();

    if (res.ok) {
      return res.val.items;
    }

    return [];
  };

  putback = async (id: string) => {
    const res = await this.backendService.putback(id);

    if (res.ok) {
      return res.val;
    }

    return Promise.reject(res.err);
  };

  delete = async (ids: string[]) => {
    const res = await this.backendService.delete(ids);

    if (res.ok) {
      return res.val;
    }

    return Promise.reject(res.err);
  };

  deleteAll = async () => {
    const res = await this.backendService.deleteAll();

    if (res.ok) {
      return res.val;
    }

    return Promise.reject(res.err);
  };

  restoreAll = async () => {
    const res = await this.backendService.restoreAll();

    if (res.ok) {
      return res.val;
    }

    return Promise.reject(res.err);
  };
}
