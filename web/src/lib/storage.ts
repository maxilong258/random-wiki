const memory = new Map<string, unknown>();
let connection: Promise<IDBDatabase> | undefined;
function database(): Promise<IDBDatabase> {
  return connection ??= new Promise((resolve, reject) => {
    const request = indexedDB.open("random-wiki-web", 1);
    request.onupgradeneeded = () => request.result.createObjectStore("data");
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => { connection = undefined; reject(request.error); };
    request.onblocked = () => { connection = undefined; reject(new Error("Storage blocked")); };
  });
}
export async function readData<T>(key: string): Promise<T | undefined> {
  const db = await database();
  return new Promise((resolve, reject) => {
    const request = db.transaction("data", "readonly").objectStore("data").get(key);
    request.onsuccess = () => resolve(request.result as T | undefined);
    request.onerror = () => reject(request.error);
  });
}
export async function writeData(key: string, value: unknown): Promise<void> {
  const db = await database();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction("data", "readwrite");
    transaction.objectStore("data").put(value, key);
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error);
  });
}
interface Cached<T> { value: T; expires: number }
export async function readCache<T>(key: string): Promise<T | undefined> {
  let cached = memory.get(key) as Cached<T> | undefined;
  if (!cached) try { cached = await readData<Cached<T>>(`cache:${key}`); } catch { /* Cache can operate in memory. */ }
  if (cached && cached.expires > Date.now()) return cached.value;
}
export async function saveCache<T>(key: string, value: T, days = 1) {
  const cached: Cached<T> = { value, expires: Date.now() + days * 86400000 };
  memory.set(key, cached);
  try { await writeData(`cache:${key}`, cached); } catch { /* Reading is still available if storage is disabled. */ }
}
export async function pruneCache() {
  try {
    const db = await database();
    const store = db.transaction("data", "readwrite").objectStore("data");
    const request = store.openCursor();
    request.onsuccess = () => {
      const cursor = request.result;
      if (!cursor) return;
      if (String(cursor.key).startsWith("cache:") && cursor.value?.expires <= Date.now()) cursor.delete();
      cursor.continue();
    };
  } catch { /* Cache cleanup must not prevent startup. */ }
}
