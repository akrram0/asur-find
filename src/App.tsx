// PRD section 4 — dashboard assembly. Window 1024x768, radius 12.
// Heading at 32,52+20; treemap card 32,104; details list from y=380.
import { useMemo, useState } from "react";
import TitleBar from "./components/TitleBar";
import Sidebar from "./components/Sidebar";
import TreemapPanel, { DEFAULT_BLOCKS } from "./components/TreemapPanel";
import FileRow from "./components/FileRow";
import ConfirmModal from "./components/ConfirmModal";
import { cleanPaths, scanRoots, type EngineEntry } from "./lib/ipc";

export default function App() {
  const [active] = useState("dashboard");
  const [entries, setEntries] = useState<EngineEntry[]>([]);
  const [pendingClean, setPendingClean] = useState<EngineEntry[] | null>(null);
  const [scanning, setScanning] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const rescan = async () => {
    setScanning(true);
    try {
      // Default demo scope: the user's projects dir. Real roots come from settings later.
      const results = await scanRoots(["C:\\Users\\Asur\\projects"]);
      setEntries(results.filter((e) => e.level !== 0));
    } finally {
      setScanning(false);
    }
  };

  const executeClean = async (permanent: boolean) => {
    if (!pendingClean) return;
    try {
      await cleanPaths(pendingClean.map((e) => e.path));
      setEntries((prev) => prev.filter((e) => !pendingClean.some((p) => p.path === e.path)));
      showToast(`${pendingClean.length} item(s) ${permanent ? "deleted" : "sent to Recycle Bin"} — Undo available`);
    } catch (err) {
      showToast(`Engine refused: ${String(err).slice(0, 80)}`);
    } finally {
      setPendingClean(null);
    }
  };

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 5000); // Undo window (PRD section 6.1)
  };

  const visibleRows = useMemo(() => entries.slice(0, 5), [entries]); // fits 768px window

  return (
    <div
      className="relative flex h-full w-full flex-col overflow-hidden"
      style={{ borderRadius: 12, boxShadow: "var(--shadow-window)" }}
    >
      <TitleBar onRescan={rescan} />

      <div className="flex min-h-0 flex-1">
        <Sidebar active={active} onNavigate={() => {}} />

        <main className="relative min-h-0 flex-1 overflow-y-auto">
          {/* heading 24px Bold + subtitle */}
          <h1 className="absolute font-bold" style={{ left: 32, top: 20, fontSize: 24 }}>
            Dashboard
          </h1>
          <p className="absolute" style={{ left: 32, top: 56, fontSize: 13, color: "var(--text-secondary)" }}>
            {scanning ? "Scanning…" : `${entries.length} cleanable items found`}
          </p>

          <TreemapPanel blocks={DEFAULT_BLOCKS} />

          {/* details list — heading at frame y=344; rows container offset so
              FileRow's frame coords (380 + i*64) land correctly */}
          <h2 className="absolute font-semibold" style={{ left: 32, top: 344, fontSize: 14 }}>
            Details
          </h2>
          <div className="absolute" style={{ left: 0, top: 104, right: 0 }}>
            {visibleRows.map((e, i) => (
              <FileRow key={e.path} index={i} entry={e} onAction={(en) => setPendingClean([en])} />
            ))}
            {!scanning && visibleRows.length === 0 && (
              <p className="absolute" style={{ left: 32, top: 300, fontSize: 13, color: "var(--text-secondary)" }}>
                Press Rescan to analyze your projects folder.
              </p>
            )}
          </div>
        </main>
      </div>

      {pendingClean && (
        <ConfirmModal
          entries={pendingClean}
          onCancel={() => setPendingClean(null)}
          onConfirm={executeClean}
        />
      )}

      {toast && (
        <div
          className="fixed bottom-[16px] left-1/2 -translate-x-1/2 rounded-btn px-[16px] py-[10px] text-white"
          style={{ background: "#333", fontSize: 12 }}
        >
          {toast}
        </div>
      )}
    </div>
  );
}