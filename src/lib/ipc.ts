// IPC bridge to the Go engine sidecar via Tauri commands.
// Falls back to a no-op mock when running in a plain browser (vite dev).

export interface EngineEntry {
  path: string;
  sizeBytes: number;
  isDir: boolean;
  modTime: string;
  level: 0 | 1 | 2 | 3;
  rationale?: string;
  action?: string;
}

export interface AuditRecord {
  timestamp: string;
  path: string;
  sizeBytes: number;
  level: number;
  result: "recycled" | "refused";
}

type TauriInvoke = (cmd: string, args?: Record<string, unknown>) => Promise<unknown>;

function getInvoke(): TauriInvoke | null {
  const w = window as unknown as { __TAURI__?: { core?: { invoke: TauriInvoke } } };
  return w.__TAURI__?.core?.invoke ?? null;
}

export async function scanRoots(roots: string[]): Promise<EngineEntry[]> {
  const invoke = getInvoke();
  if (!invoke) return [];
  return (await invoke("scan_roots", { roots })) as EngineEntry[];
}

export async function cleanPaths(paths: string[]): Promise<AuditRecord[]> {
  const invoke = getInvoke();
  if (!invoke) throw new Error("engine unavailable outside the Tauri shell");
  return (await invoke("clean_paths", { paths })) as AuditRecord[];
}

/** >5 GB or >10 items requires typing DELETE (PRD section 6.1). */
export function needsTypedConfirmation(totalSize: number, itemCount: number): boolean {
  return totalSize > 5 * 1024 * 1024 * 1024 || itemCount > 10;
}

export function formatSize(bytes: number): string {
  if (bytes >= 1024 ** 3) return `${(bytes / 1024 ** 3).toFixed(1)} GB`;
  if (bytes >= 1024 ** 2) return `${(bytes / 1024 ** 2).toFixed(1)} MB`;
  if (bytes >= 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${bytes} B`;
}