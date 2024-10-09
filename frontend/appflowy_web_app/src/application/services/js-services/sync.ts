import { updateCollab } from '@/application/services/js-services/http/http_api';
import { CollabOrigin } from '@/application/types';
import { debounce } from 'lodash-es';
import * as Y from 'yjs';

const VERSION_VECTOR_KEY = 'ydoc_version_vector';
const UNSYNCED_FLAG_KEY = 'ydoc_unsynced_changes';
const LAST_SYNCED_AT_KEY = 'ydoc_last_synced_at';

export class SyncManager {

  private versionVector: number;

  private lastSyncedAt: string;

  private hasUnsyncedChanges: boolean = false;

  private isSending = false;

  constructor (private doc: Y.Doc, private uuid: string, private workspaceId: string, private objectId: string) {
    this.versionVector = this.loadVersionVector();
    this.hasUnsyncedChanges = this.loadUnsyncedFlag();
    this.lastSyncedAt = this.loadLastSyncedAt();
    this.setupListener();
  }

  private setupListener () {
    this.doc.on('update', (_update: Uint8Array, origin: CollabOrigin) => {
      if (origin === CollabOrigin.Remote) return;

      this.debouncedSendUpdate();
    });
  }

  private getStorageKey (baseKey: string): string {
    return `${this.uuid}_${baseKey}_${this.workspaceId}_${this.objectId}`;
  }

  private loadVersionVector (): number {
    const storedVector = localStorage.getItem(this.getStorageKey(VERSION_VECTOR_KEY));

    return storedVector ? parseInt(storedVector, 10) : 0;
  }

  private saveVersionVector () {
    localStorage.setItem(this.getStorageKey(VERSION_VECTOR_KEY), this.versionVector.toString());
  }

  private loadUnsyncedFlag (): boolean {
    return localStorage.getItem(this.getStorageKey(UNSYNCED_FLAG_KEY)) === 'true';
  }

  private saveUnsyncedFlag () {
    localStorage.setItem(this.getStorageKey(UNSYNCED_FLAG_KEY), this.hasUnsyncedChanges.toString());
  }

  private loadLastSyncedAt (): string {
    return localStorage.getItem(this.getStorageKey(LAST_SYNCED_AT_KEY)) || '';
  }

  private saveLastSyncedAt () {
    localStorage.setItem(this.getStorageKey(LAST_SYNCED_AT_KEY), this.lastSyncedAt);
  }

  private debouncedSendUpdate = debounce(() => {
    this.hasUnsyncedChanges = true;
    this.saveUnsyncedFlag();

    void this.sendUpdate();
  }, 1000);  // 1 second debounce

  private async sendUpdate () {
    if (this.isSending) return;
    this.isSending = true;

    try {
      // Increment version vector before sending
      this.versionVector++;
      this.saveVersionVector();

      const update = Y.encodeStateAsUpdate(this.doc);
      const context = { version_vector: this.versionVector };

      const response = await updateCollab(this.workspaceId, this.objectId, update, context);

      if (response) {
        console.log(`Update sent successfully. Server version: ${response.version_vector}`);

        // Update last synced time
        this.lastSyncedAt = String(Date.now());
        this.saveLastSyncedAt();

        if (response.version_vector === this.versionVector) {
          // Our update was the latest
          this.hasUnsyncedChanges = false;
          this.saveUnsyncedFlag();
          console.log('Local changes fully synced');
        } else {
          // There are still unsynced changes (possibly from other clients)
          this.hasUnsyncedChanges = true;
          this.saveUnsyncedFlag();
          console.log('There are still unsynced changes');
        }
      } else {
        return Promise.reject(response);
      }
    } catch (error) {
      console.error('Failed to send update:', error);
      // Keep the unsynced flag as true
      this.hasUnsyncedChanges = true;
      this.saveUnsyncedFlag();
    } finally {
      this.isSending = false;
    }
  }

  public initialize () {
    if (this.hasUnsyncedChanges) {
      // Send an update if there are unsynced changes
      void this.sendUpdate();
    }
  }

  public getUnsyncedStatus (): boolean {
    return this.hasUnsyncedChanges;
  }

  public getLastSyncedAt (): string {
    return this.lastSyncedAt;
  }

  public getCurrentVersionVector (): number {
    return this.versionVector;
  }
}