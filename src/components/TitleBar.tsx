// PRD section 4.1 — title bar: 0,0 -> 1024x52.
// Windows-style controls top-right (min/max/close) — no macOS traffic lights.
import { getCurrentWindow } from "@tauri-apps/api/window";
import { IconMinimize, IconMaximize, IconClose, IconRefresh } from "./icons";

export default function TitleBar({ onRescan }: { onRescan: () => void }) {
  const appWindow = getCurrentWindow();

  return (
    <div
      data-tauri-drag-region
      className="relative flex h-[52px] w-full shrink-0 items-center bg-titlebar"
      style={{ borderBottom: "1px solid var(--divider)" }}
    >
      {/* centered title: 13px Semi Bold */}
      <span
        className="absolute left-1/2 -translate-x-1/2 font-semibold"
        style={{ fontSize: 13 }}
      >
        Asur Find
      </span>

      {/* Rescan button: x=796 y=12 w=112 h=28 */}
      <button
        onClick={onRescan}
        className="absolute flex items-center justify-center gap-[6px] rounded-btn text-white transition-opacity hover:opacity-90"
        style={{
          left: 796,
          top: 12,
          width: 112,
          height: 28,
          fontSize: 11,
          fontWeight: 600,
          background: "var(--accent)",
        }}
      >
        <IconRefresh size={13} /> Rescan
      </button>

      {/* window controls, right-aligned */}
      <div className="ml-auto flex h-full">
        <button
          onClick={() => appWindow.minimize()}
          className="flex h-full w-[46px] items-center justify-center hover:bg-black/10"
          aria-label="Minimize"
        >
          <IconMinimize size={14} />
        </button>
        <button
          onClick={() => appWindow.toggleMaximize()}
          className="flex h-full w-[46px] items-center justify-center hover:bg-black/10"
          aria-label="Maximize"
        >
          <IconMaximize size={13} />
        </button>
        <button
          onClick={() => appWindow.close()}
          className="flex h-full w-[46px] items-center justify-center hover:bg-red-500 hover:text-white"
          aria-label="Close"
        >
          <IconClose size={14} />
        </button>
      </div>
    </div>
  );
}