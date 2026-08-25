// PRD section 4.2 — sidebar with real Windows backdrop blur (Acrylic/Mica is
// applied by the Tauri window; the glass tint here layers on top of it).
import { IconGrid, IconFolder, IconDoc, IconLayers, IconSettings } from "./icons";

const NAV = [
  { id: "dashboard", label: "Dashboard", icon: IconGrid },
  { id: "folders", label: "Folders", icon: IconFolder },
  { id: "files", label: "Files", icon: IconDoc },
  { id: "layers", label: "Categories", icon: IconLayers },
  { id: "settings", label: "Settings", icon: IconSettings },
] as const;

export default function Sidebar({
  active,
  onNavigate,
}: {
  active: string;
  onNavigate: (id: string) => void;
}) {
  return (
    <nav
      className="flex h-full w-[220px] shrink-0 flex-col gap-[4px] p-[16px]"
      style={{
        background: "var(--sidebar-bg)",
        backdropFilter: `blur(var(--sidebar-blur))`,
        WebkitBackdropFilter: `blur(var(--sidebar-blur))`,
        borderRight: "1px solid var(--divider)",
      }}
    >
      {/* greeting: 13px Semi Bold, accent color */}
      <div
        className="mb-[16px] px-[12px] font-semibold"
        style={{ fontSize: 13, color: "var(--accent)" }}
      >
        Hello, Asur
      </div>

      {NAV.map(({ id, label, icon: Icon }) => {
        const isActive = active === id;
        return (
          <button
            key={id}
            onClick={() => onNavigate(id)}
            className="flex items-center gap-[10px] rounded-btn px-[12px] py-[8px] text-left transition-colors"
            style={{
              fontSize: 13,
              fontWeight: isActive ? 600 : 500, // active Semi Bold / inactive Medium
              background: isActive ? "var(--accent)" : "transparent",
              color: isActive ? "#fff" : "var(--text-primary)",
            }}
          >
            <Icon size={15} />
            {label}
          </button>
        );
      })}
    </nav>
  );
}