// Types for file storage
interface StoredFileData {
  id: string;
  file: File;
  name: string;
  type: string;
  size: number;
  lastModified: number;
  timestamp: number;
}

// Main class for IndexedDB file storage operations
class FileStorage {
  private dbName: string;
  private storeName: string;
  private db: IDBDatabase | null;

  constructor(dbName: string = 'FileStorage', storeName: string = 'files') {
    this.dbName = dbName;
    this.storeName = storeName;
    this.db = null;
  }

  // Initialize IndexedDB connection
  async init(): Promise<void> {
    if (this.db) return;

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, 1);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };

      request.onupgradeneeded = (event: IDBVersionChangeEvent) => {
        const db = (event.target as IDBOpenDBRequest).result;

        if (!db.objectStoreNames.contains(this.storeName)) {
          db.createObjectStore(this.storeName, { keyPath: 'id' });
        }
      };
    });
  }

  // Save file to IndexedDB
  async saveFile(file: File, customId?: string): Promise<string> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    const id = customId || crypto.randomUUID();
    const fileData: StoredFileData = {
      id,
      file,
      name: file.name,
      type: file.type,
      size: file.size,
      lastModified: file.lastModified,
      timestamp: Date.now(),
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(this.storeName, 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.put(fileData);

      request.onsuccess = () => resolve(id);
      request.onerror = () => reject(request.error);
    });
  }

  // Retrieve file from IndexedDB by ID
  async getFile(id: string): Promise<StoredFileData | null> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(this.storeName, 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.get(id);

      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  // Delete file from IndexedDB
  async deleteFile(id: string): Promise<void> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(this.storeName, 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.delete(id);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  // Get all stored files
  async getAllFiles(): Promise<StoredFileData[]> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(this.storeName, 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.getAll();

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  // Clear all stored files
  async clear(): Promise<void> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction(this.storeName, 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.clear();

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }
}

// Interface for file handling results
interface FileHandlingResult {
  id: string;
  url: string;
  name: string;
  type: string;
  size: number;
}

// Main class for handling file operations including URL management
export class FileHandler {
  private storage: FileStorage;
  private fileUrls: Map<string, string>;

  constructor() {
    this.storage = new FileStorage();
    this.fileUrls = new Map();
  }

  // Handle file upload and create object URL
  async handleFileUpload(file: File): Promise<FileHandlingResult> {
    try {
      const fileId = await this.storage.saveFile(file);
      const url = URL.createObjectURL(file);

      this.fileUrls.set(fileId, url);

      return {
        id: fileId,
        url,
        name: file.name,
        type: file.type,
        size: file.size,
      };
    } catch (error) {
      console.error('Error handling file upload:', error);
      throw error;
    }
  }

  // Retrieve stored file and manage its object URL
  async getStoredFile(id: string): Promise<(StoredFileData & { url: string }) | null> {
    try {
      const fileData = await this.storage.getFile(id);

      if (!fileData) return null;

      // Return existing URL if available
      if (this.fileUrls.has(id)) {
        return {
          ...fileData,
          url: this.fileUrls.get(id)!,
        };
      }

      // Create new URL if needed
      const url = URL.createObjectURL(fileData.file);

      this.fileUrls.set(id, url);

      return {
        ...fileData,
        url,
      };
    } catch (error) {
      console.error('Error getting stored file:', error);
      throw error;
    }
  }

  // Clean up single file and its resources
  async cleanup(id: string): Promise<void> {
    if (this.fileUrls.has(id)) {
      URL.revokeObjectURL(this.fileUrls.get(id)!);
      this.fileUrls.delete(id);
    }

    await this.storage.deleteFile(id);
  }

  // Clean up all files and resources
  async cleanupAll(): Promise<void> {
    for (const url of this.fileUrls.values()) {
      URL.revokeObjectURL(url);
    }

    this.fileUrls.clear();
    await this.storage.clear();
  }
}

export const MAX_FILE_SIZE = 7 * 1024 * 1024;
