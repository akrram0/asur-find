// PRD section 6.1 Layer 2 — confirmation modal.
// 420px card, radius 14, 24px padding, dim rgba(0,0,0,0.35) overlay.
// >5GB or >10 items requires typing DELETE (PRD: prevents one-misclick wipes).
// Every action shows exact path + size + classification badge + rationale.
import { useMemo, useState } from "react";
import type { EngineEntry } from "../lib/ipc";
import { formatSize, needsTypedConfirmation } from "../lib/ipc";
import { IconCheck, IconExclaim } from "./icons";

export default function ConfirmModal({
  entries,
  onCancel,
  onConfirm,
}: {
  entries: EngineEntry[];
  onCancel: () => void;
  onConfirm: (permanent: boolean) => void;
}) {
  const totalSize = useMemo(() => entries.reduce((a, e) => a + e.sizeBytes, 0), [entries]);
  const typedNeeded = needsTypedConfirmation(totalSize, entries.length);
  const [typed, setTyped] = useState("");
  const [permanent, setPermanent] = useState(false);
  const [permanentConfirmed, setPermanentConfirmed] = useState(false);

  const level = entries.some((e) => e.level === 2) ? 2 : 1;
  const canConfirm = (!typedNeeded || typed === "DELETE") &&
    (!permanent || permanentConfirmed);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center"
      style={{ background: "rgba(0,0,0,0.35)" }}
      onClick={onCancel}
    >
      <div
        className="flex flex-col gap-[12px]"
        style={{
          width: 420,
          borderRadius: 14,
          padding: 24,
          background: "var(--bg-card)",
          boxShadow: "var(--shadow-window)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* header */}
        <div className="flex items-center gap-[8px]">
          <span
            className="flex h-[24px] w-[24px] items-center justify-center rounded-full text-white"
            style={{ background: level === 1 ? "var(--safe)" : "var(--review)" }}
          >
            {level === 1 ? <IconCheck size={13} /> : <IconExclaim size={13} />}
          </span>
          <h2 className="font-semibold" style={{ fontSize: 16 }}>
            Confirm Clean
          </h2>
        </div>

        {/* body */}
        <div className="flex flex-col gap-[4px]">
          {entries.map((e) => (
            <div key={e.path} className="truncate font-mono" style={{ fontSize: 12, color: "var(--text-secondary)" }}>
              {e.path}
            </div>
          ))}
          <div style={{ fontSize: 14 }} className="font-bold">
            {formatSize(totalSize)} · {entries.length} item{entries.length > 1 ? "s" : ""}
          </div>
          <div className="flex items-center gap-[6px]">
            <span
              className="rounded-btn px-[8px] py-[2px] text-white"
              style={{
                fontSize: 11,
                fontWeight: 600,
                background: level === 1 ? "var(--safe)" : "var(--review)",
              }}
            >
              {level === 1 ? "Safe" : "Review"}
            </span>
            <span style={{ fontSize: 12, color: "var(--text-secondary)" }}>
              {entries[0]?.rationale ?? ""}
            </span>
          </div>
        </div>

        {/* DELETE escalation */}
        {typedNeeded && (
          <input
            autoFocus
            value={typed}
            onChange={(e) => setTyped(e.target.value)}
            placeholder={`Type DELETE to confirm ${formatSize(totalSize)}`}
            className="rounded-btn px-[10px] py-[7px]"
            style={{
              border: "1px solid var(--divider)",
              background: "var(--bg-window)",
              color: "var(--text-primary)",
              fontSize: 13,
            }}
          />
        )}

        {/* permanent delete toggle — separate extra confirmation required */}
        <label className="flex items-center gap-[8px]" style={{ fontSize: 12 }}>
          <input type="checkbox" checked={permanent} onChange={(e) => setPermanent(e.target.checked)} />
          Permanently delete (skip Recycle Bin)
        </label>
        {permanent && !permanentConfirmed && (
          <button
            onClick={() => setPermanentConfirmed(true)}
            className="self-start rounded-btn px-[10px] py-[5px]"
            style={{ fontSize: 11, fontWeight: 600, border: "1px solid var(--review)", color: "var(--review)" }}
          >
            I understand — permanent erase cannot be undone
          </button>
        )}

        {/* footer buttons right-aligned, 36px tall, 8px gap */}
        <div className="mt-[8px] flex justify-end gap-[8px]">
          <button
            onClick={onCancel}
            className="rounded-btn"
            style={{ height: 36, padding: "0 16px", fontSize: 11, fontWeight: 600, border: "1px solid var(--divider)", color: "var(--text-secondary)" }}
          >
            Cancel
          </button>
          <button
            disabled={!canConfirm}
            onClick={() => onConfirm(permanent)}
            className="rounded-btn text-white disabled:opacity-40"
            style={{
              height: 36,
              padding: "0 16px",
              fontSize: 11,
              fontWeight: 600,
              background: level === 1 ? "var(--safe)" : "var(--review)",
            }}
          >
            {permanent ? "Delete Forever" : "Move to Recycle Bin"}
          </button>
        </div>
      </div>
    </div>
  );
}