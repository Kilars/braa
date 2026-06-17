import type { GameSave } from './save';

export interface Storage {
  load(): Promise<GameSave | null>;
  save(s: GameSave): Promise<void>;
  clear(): Promise<void>;
}

export class InMemoryStorage implements Storage {
  private data: GameSave | null = null;

  async load(): Promise<GameSave | null> {
    return this.data;
  }

  async save(s: GameSave): Promise<void> {
    this.data = s;
  }

  async clear(): Promise<void> {
    this.data = null;
  }
}

export class IndexedDbStorage implements Storage {
  private readonly dbName: string;
  private readonly storeName = 'saves';
  private readonly key = 'current';

  constructor(dbName = 'bra-save') {
    this.dbName = dbName;
  }

  private openDb(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, 1);
      request.onupgradeneeded = () => {
        request.result.createObjectStore(this.storeName);
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async load(): Promise<GameSave | null> {
    const db = await this.openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(this.storeName, 'readonly');
      const req = tx.objectStore(this.storeName).get(this.key);
      req.onsuccess = () => resolve(req.result ?? null);
      req.onerror = () => reject(req.error);
    });
  }

  async save(s: GameSave): Promise<void> {
    const db = await this.openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(this.storeName, 'readwrite');
      const req = tx.objectStore(this.storeName).put(s, this.key);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  async clear(): Promise<void> {
    const db = await this.openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(this.storeName, 'readwrite');
      const req = tx.objectStore(this.storeName).delete(this.key);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }
}
