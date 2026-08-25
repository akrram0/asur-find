// PRD section 4.2 — Details list row: 56px tall, 64px pitch, radius 10,
// 1px divider stroke. Status icon 20x20 at ~44,row+18; name at 84,row+8;
// path at 84,row+30; size right-aligned w80; action button x=690-786, h=28.
// Locked rows render everything at 50% opacity with a "Protected" label.
import type { EngineEntry } from "../lib/ipc";
import { formatSize } from "../lib/ipc";
import { IconCheck, IconExclaim, IconLock, IconMagnifier, IconArchiveBox } from "./icons";

const statusIcon = (level: number) => {
  switch (level) {
    case 1: // safe — white on green circle
      return { bg: "var(--safe)", el: <IconCheck size={11} color="#fff" /> };
    case 2: // review — white on orange
      return { bg: "var(--review)", el: <IconExclaim size={11} color="#fff" /> };
    default: // locked — gray padlock 50%
      return { bg: "var(--locked)", el: <IconLock size={11} color="#fff" /> };
  }
};

export default function FileRow({
  index,
  entry,
  onAction,
}: {
  index: number;
  entry: EngineEntry;
  onAction: (entry: EngineEntry) => void;
}) {
  const rowY = 380 + index * 64; // 64px pitch
  const locked = entry.level === 3 || entry.level === 0;
  const ic = statusIcon(entry.level);

  const actionBtn =
    entry.level === 1 ? (
      { label: "Clean", icon: <IconCheck size={11} />, bg: "var(--safe)" }
    ) : entry.level === 2 ? (
      { label: "Review", icon: <IconMagnifier size={11} />, bg: "var(--review)" }
    ) : null;

  return (
    <div
      className="absolute flex items-center rounded-row"
      style={{
        left: 32,
        top: rowY - 104,
        width: 740,
        height: 56,
        opacity: locked ? 0.5 : 1, // PRD: locked rows visually "don't touch"
        background: "var(--bg-card)",
        border: "1px solid var(--divider)",
      }}
    >
      {/* status icon: 20x20 circle */}
      <div
        className="absolute flex items-center justify-center rounded-full"
        style={{ left: 12, top: 18, width: 20, height: 20, background: ic.bg }}
      >
        {ic.el}
      </div>

      {/* file name + path stacked */}
      <div className="absolute" style={{ left: 52, top: 8, width: 400 }}>
        <div className="truncate font-medium" style={{ fontSize: 13, height: 20 }}>
          {entry.path.split("\\").pop()}
        </div>
        <div
          className="truncate font-mono"
          style={{ fontSize: 11, height: 16, color: "var(--text-secondary)" }}
        >
          {entry.path}
        </div>
      </div>

      {/* size right-aligned w80 */}
      <span
        className="absolute text-right font-semibold"
        style={{ right: 120, width: 80, fontSize: 12 }}
      >
        {formatSize(entry.sizeBytes)}
      </span>

      {/* action button (Level 1/2 only) or Protected label */}
      {locked || !actionBtn ? (
        <span
          className="absolute rounded-btn px-[10px] py-[5px]"
          style={{ right: 20, fontSize: 11, fontWeight: 600, color: "var(--text-secondary)" }}
        >
          Protected
        </span>
      ) : (
        <button
          onClick={() => onAction(entry)}
          className="absolute flex items-center justify-center gap-[4px] rounded-btn text-white hover:opacity-90"
          style={{ right: 20, width: 96, height: 28, background: actionBtn.bg, fontSize: 11, fontWeight: 600 }}
        >
          {actionBtn.icon}
          {actionBtn.label}
        </button>
      )}
    </div>
  );
}

export { IconArchiveBox };