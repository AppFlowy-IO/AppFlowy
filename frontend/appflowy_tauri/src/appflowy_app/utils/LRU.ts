class ListNode<T> {
  public key: string;
  public value: T;
  public prev: ListNode<T> | null;
  public next: ListNode<T> | null;

  constructor(key: string, value: T) {
    this.key = key;
    this.value = value;
    this.prev = null;
    this.next = null;
  }
}

export class LRUCache<T> {
  private capacity: number;
  private map: Map<string, ListNode<T>>;
  private head: ListNode<T> | null;
  private tail: ListNode<T> | null;

  constructor(capacity: number) {
    this.capacity = capacity;
    this.map = new Map<string, ListNode<T>>();
    this.head = null;
    this.tail = null;
  }

  public get(key: string): T | undefined {
    if (this.map.has(key)) {
      const node = this.map.get(key)!;
      this.moveToHead(node);
      return node.value;
    } else {
      return undefined;
    }
  }

  public put(key: string, value: T): void {
    if (this.map.has(key)) {
      const node = this.map.get(key)!;
      node.value = value;
      this.moveToHead(node);
    } else {
      const newNode = new ListNode<T>(key, value);
      this.map.set(key, newNode);
      this.addToHead(newNode);

      if (this.map.size > this.capacity) {
        const tail = this.removeTail();
        this.map.delete(tail.key);
      }
    }
  }

  public delete(key: string) {
    this.map.delete(key);
  }

  clear() {
    this.map.clear();
    this.head = null;
    this.tail = null;
  }

  private moveToHead(node: ListNode<T>): void {
    if (node === this.head) {
      return;
    }

    if (node.prev) {
      node.prev.next = node.next;
    }

    if (node.next) {
      node.next.prev = node.prev;
    }

    if (node === this.tail) {
      this.tail = node.prev;
    }

    if (!this.head || !this.tail) {
      this.head = node;
      this.tail = node;
      return;
    }

    node.prev = null;
    node.next = this.head;
    this.head.prev = node;
    this.head = node;
  }

  private addToHead(node: ListNode<T>): void {
    if (!this.head || !this.tail) {
      this.head = node;
      this.tail = node;
    } else {
      node.prev = null;
      node.next = this.head;
      this.head.prev = node;
      this.head = node;
    }
  }

  private removeTail(): ListNode<T> {
    const node = this.tail!;
    if (this.tail === this.head) {
      this.tail = null;
      this.head = null;
    } else {
      this.tail = this.tail!.prev!;
      this.tail.next = null;
    }
    return node;
  }
}
