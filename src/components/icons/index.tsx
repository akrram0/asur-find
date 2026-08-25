/* PRD section 5 — hand-built inline SVG icon set.
   Monochrome, stroke-based, no external icon library. */
import React from "react";

type P = React.SVGProps<SVGSVGElement> & { size?: number };

const base = ({ size = 16, ...rest }: P): React.SVGProps<SVGSVGElement> => ({
  width: size,
  height: size,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 2,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
  "aria-hidden": true,
  ...rest,
});

// ---- Sidebar ----
export const IconGrid = (p: P) => (
  <svg {...base(p)}>
    <rect x="3" y="3" width="7" height="7" rx="1.5" />
    <rect x="14" y="3" width="7" height="7" rx="1.5" />
    <rect x="3" y="14" width="7" height="7" rx="1.5" />
    <rect x="14" y="14" width="7" height="7" rx="1.5" />
  </svg>
);

export const IconFolder = (p: P) => (
  <svg {...base(p)}>
    <path d="M3 6a2 2 0 0 1 2-2h4l2 3h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6z" />
  </svg>
);

export const IconDoc = (p: P) => (
  <svg {...base(p)}>
    <rect x="5" y="3" width="14" height="18" rx="2" />
    <line x1="9" y1="9" x2="15" y2="9" />
    <line x1="9" y1="13" x2="15" y2="13" />
  </svg>
);

export const IconLayers = (p: P) => (
  <svg {...base(p)}>
    <rect x="4" y="4" width="12" height="12" rx="1.5" />
    <rect x="8" y="8" width="12" height="12" rx="1.5" />
  </svg>
);

export const IconSettings = (p: P) => (
  <svg {...base(p)}>
    <line x1="4" y1="7" x2="20" y2="7" />
    <circle cx="10" cy="7" r="2.2" fill="currentColor" stroke="none" />
    <line x1="4" y1="15" x2="20" y2="15" />
    <circle cx="16" cy="15" r="2.2" fill="currentColor" stroke="none" />
  </svg>
);

// ---- Status ----
export const IconCheck = (p: P) => (
  <svg {...base({ strokeWidth: 3, ...p })}>
    <polyline points="5,13 10,18 19,7" />
  </svg>
);

export const IconExclaim = (p: P) => (
  <svg {...base({ strokeWidth: 2.5, ...p })}>
    <line x1="12" y1="5" x2="12" y2="14" />
    <circle cx="12" cy="19" r="1.6" fill="currentColor" stroke="none" />
  </svg>
);

export const IconLock = (p: P) => (
  <svg {...base(p)}>
    <rect x="5" y="11" width="14" height="9" rx="2" />
    <path d="M8 11V7a4 4 0 0 1 8 0v4" />
  </svg>
);

// ---- Action buttons ----
export const IconMagnifier = (p: P) => (
  <svg {...base(p)}>
    <circle cx="10.5" cy="10.5" r="6" />
    <line x1="15" y1="15" x2="20" y2="20" />
  </svg>
);

export const IconArchiveBox = (p: P) => (
  <svg {...base(p)}>
    <rect x="3" y="4" width="18" height="5" rx="1" />
    <path d="M5 9v9a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V9" />
    <line x1="10" y1="13" x2="14" y2="13" />
  </svg>
);

// ---- Title bar ----
export const IconRefresh = (p: P) => (
  <svg {...base(p)}>
    <path d="M20 12a8 8 0 1 1-2.34-5.66" />
    <polyline points="20,3 20,7.5 15.5,7.5" />
  </svg>
);

export const IconMinimize = (p: P) => (
  <svg {...base(p)}>
    <line x1="5" y1="12" x2="19" y2="12" />
  </svg>
);

export const IconMaximize = (p: P) => (
  <svg {...base(p)}>
    <rect x="5.5" y="5.5" width="13" height="13" rx="1" />
  </svg>
);

export const IconClose = (p: P) => (
  <svg {...base(p)}>
    <line x1="6" y1="6" x2="18" y2="18" />
    <line x1="18" y1="6" x2="6" y2="18" />
  </svg>
);