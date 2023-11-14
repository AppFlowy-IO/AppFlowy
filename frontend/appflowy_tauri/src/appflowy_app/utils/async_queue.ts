import { Log } from '$app/utils/log';

export class AsyncQueue<T = unknown> {
  private queue: T[] = [];
  private isProcessing = false;
  private executeFunction: (item: T) => Promise<void>;

  constructor(executeFunction: (item: T) => Promise<void>) {
    this.executeFunction = executeFunction;
  }

  enqueue(item: T): void {
    this.queue.push(item);
    this.processQueue();
  }

  private processQueue(): void {
    if (this.isProcessing || this.queue.length === 0) {
      return;
    }

    const item = this.queue.shift();

    if (!item) {
      return;
    }

    this.isProcessing = true;

    const executeFn = async (item: T) => {
      try {
        await this.processItem(item);
      } catch (error) {
        Log.error('queue processing error:', error);
      } finally {
        this.isProcessing = false;
        this.processQueue();
      }
    };

    void executeFn(item);
  }

  private async processItem(item: T): Promise<void> {
    try {
      await this.executeFunction(item);
    } catch (error) {
      Log.error('queue processing error:', error);
    }
  }
}
