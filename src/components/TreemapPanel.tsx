// PRD section 4.2 — Disk Composition card: x=32 y=104 w=740 h=220, radius 12.
// Treemap blocks are positioned relative to the main frame (PRD warning in §4).
import { formatSize } from "../lib/ipc";

export interface Block {
  label: string;
  bytes: number;
  x: number;
  y: number;
  w: number;
  h: number;
  fill: string;
  opacity?: number;
}

// Exact block map from PRD section 4.2 (coordinates relative to main frame).
export const DEFAULT_BLOCKS: Block[] = [
  { label: "Dev Clutter", bytes: 210 * 1024 ** 3, x: 52, y: 156, w: 280, h: 150, fill: "var(--locked)", opacity: 0.9 },
  { label: "Node Modules", bytes: 64 * 1024 ** 3, x: 340, y: 156, w: 170, h: 70, fill: "var(--locked)", opacity: 0.65 },
  { label: "Build Caches", bytes: 38 * 1024 ** 3, x: 340, y: 232, w: 170, h: 74, fill: "var(--locked)", opacity: 0.45 },
  { label: "Large Files", bytes: 52 * 1024 ** 3, x: 518, y: 156, w: 120, h: 70, fill: "var(--accent)", opacity: 0.85 },
  { label: "Review sliver", bytes: 6 * 1024 ** 3, x: 518, y: 232, w: 120, h: 36, fill: "var(--review)", opacity: 0.6 },
  { label: "Safe sliver", bytes: 4 * 1024 ** 3, x: 518, y: 270, w: 120, h: 36, fill: "var(--safe)", opacity: 0.6 },
  { label: "System (locked)", bytes: 96 * 1024 ** 3, x: 646, y: 156, w: 114, h: 150, fill: "#8E8E93", opacity: 1 },
];

const LEGEND = ["CATEGORIES", "Dev Clutter", "Node Modules", "Build Caches", "Large Files", "System"];

export default function TreemapPanel({ blocks = DEFAULT_BLOCKS }: { blocks?: Block[] }) {
  return (
    <section
      className="absolute rounded-win bg-card"
      style={{
        left: 32,
        top: 104,
        width: 740,
        height: 220,
        boxShadow: "0 1px 3px rgba(0,0,0,0.06)",
        border: "1px solid var(--divider)",
      }}
    >
      {/* label at 52,124 -> relative 20,20 */}
      <span
        className="absolute font-semibold"
        style={{ left: 20, top: 20, fontSize: 14 }}
      >
        Disk Composition
      </span>

      {blocks.map((b) => (
        <div
          key={b.label}
          title={`${b.label} — ${formatSize(b.bytes)}`}
          className="absolute rounded-block"
          style={{
            // PRD: block coords are relative to the MAIN FRAME; the card sits
            // at 32,104 inside that frame, so subtract both offsets here.
            left: b.x - 32,
            top: b.y - 104,
            width: b.w,
            height: b.h,
            background: b.fill,
            opacity: b.opacity ?? 1,
            outline: "2px solid var(--bg-window)", // white/dark gap stroke
          }}
        >
          {b.h >= 60 && (
            <span
              className="absolute left-[8px] top-[8px] font-medium text-white"
              style={{ fontSize: 12, textShadow: "0 1px 2px rgba(0,0,0,0.35)" }}
            >
              {b.label}
              <br />
              <span style={{ fontSize: 11 }}>{formatSize(b.bytes)}</span>
            </span>
          )}
        </div>
      ))}

      {/* legend */}
      <div className="absolute flex flex-col gap-[2px]" style={{ left: 20, bottom: 10 }}>
        {LEGEND.map((l, i) => (
          <span
            key={l}
            style={{
              fontSize: i === 0 ? 11 : 12,
              fontWeight: i === 0 ? 600 : 500,
              letterSpacing: i === 0 ? "0.06em" : undefined,
              color: i === 0 ? "var(--text-secondary)" : "var(--text-primary)",
            }}
          >
            {i === 0 ? l.toUpperCase() : l}
          </span>
        ))}
      </div>
    </section>
  );
}