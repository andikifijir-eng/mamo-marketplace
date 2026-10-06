import React from 'react';
import type { ReactNode } from 'react';

/** Ikon sederhana (stroke) — biar tidak perlu library eksternal. */
type IconProps = { size?: number; color?: string; className?: string };

const S = ({ size = 18, color = 'currentColor' }: IconProps) => ({
  width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
  stroke: color, strokeWidth: 1.9, strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
});

export const IconDashboard = (p: IconProps) => (
  <svg {...S(p)}><rect x="3" y="3" width="7" height="9" rx="1.5" /><rect x="14" y="3" width="7" height="5" rx="1.5" /><rect x="14" y="12" width="7" height="9" rx="1.5" /><rect x="3" y="16" width="7" height="5" rx="1.5" /></svg>
);
export const IconFlag = (p: IconProps) => (
  <svg {...S(p)}><path d="M4 21V4" /><path d="M4 5h13l-2 4 2 4H4" /></svg>
);
export const IconListings = (p: IconProps) => (
  <svg {...S(p)}><rect x="3" y="4" width="18" height="16" rx="2" /><path d="M3 9h18M8 14h8" /></svg>
);
export const IconUsers = (p: IconProps) => (
  <svg {...S(p)}><circle cx="9" cy="8" r="3.2" /><path d="M2.5 20a6.5 6.5 0 0113 0" /><path d="M16 5.5a3 3 0 010 5.6M18 20a6 6 0 00-2-4.5" /></svg>
);
export const IconReports = (p: IconProps) => (
  <svg {...S(p)}><path d="M6 3h9l5 5v13H6z" /><path d="M15 3v5h5" /><path d="M9 13h6M9 17h6" /></svg>
);
export const IconAnalytics = (p: IconProps) => (
  <svg {...S(p)}><path d="M3 21h18" /><path d="M6 21V10M11 21V4M16 21v-7M21 21v-11" /></svg>
);
export const IconBell = (p: IconProps) => (
  <svg {...S(p)}><path d="M18 8a6 6 0 10-12 0c0 6-3 7-3 7h18s-3-1-3-7" /><path d="M13.7 21a2 2 0 01-3.4 0" /></svg>
);
export const IconLogout = (p: IconProps) => (
  <svg {...S(p)}><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" /><path d="M16 17l5-5-5-5M21 12H9" /></svg>
);
export const IconSearch = (p: IconProps) => (
  <svg {...S(p)}><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></svg>
);
export const IconCheck = (p: IconProps) => (
  <svg {...S(p)}><path d="M20 6L9 17l-5-5" /></svg>
);
export const IconX = (p: IconProps) => (
  <svg {...S(p)}><path d="M18 6L6 18M6 6l12 12" /></svg>
);
export const IconClock = (p: IconProps) => (
  <svg {...S(p)}><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3.5 2" /></svg>
);
export const IconBox = (p: IconProps) => (
  <svg {...S(p)}><path d="M21 8l-9-5-9 5 9 5 9-5z" /><path d="M3 8v8l9 5 9-5V8" /><path d="M12 13v8" /></svg>
);
export const IconWallet = (p: IconProps) => (
  <svg {...S(p)}><rect x="2.5" y="6" width="19" height="13" rx="2.5" /><path d="M2.5 10h19" /><circle cx="17" cy="14" r="1.2" fill="currentColor" /></svg>
);
export const IconStar = (p: IconProps) => (
  <svg {...S(p)}><path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z" /></svg>
);
export const IconStore = (p: IconProps) => (
  <svg {...S(p)}><path d="M3 9l1.5-5h15L21 9" /><path d="M3 9h18v10a1 1 0 01-1 1H4a1 1 0 01-1-1z" /><path d="M9 20v-6h6v6" /></svg>
);
export const IconChevron = (p: IconProps) => (
  <svg {...S(p)}><path d="M9 6l6 6-6 6" /></svg>
);
export const IconKebab = (p: IconProps) => (
  <svg {...S(p)}><circle cx="12" cy="5" r="1.4" fill="currentColor" /><circle cx="12" cy="12" r="1.4" fill="currentColor" /><circle cx="12" cy="19" r="1.4" fill="currentColor" /></svg>
);
export const IconImage = (p: IconProps) => (
  <svg {...S(p)}><rect x="3" y="4" width="18" height="16" rx="2" /><circle cx="9" cy="10" r="2" /><path d="M3 17l5-5 4 4 3-3 6 6" /></svg>
);
export const IconInbox = (p: IconProps) => (
  <svg {...S(p)}><path d="M3 13h5l2 3h4l2-3h5" /><path d="M5 5h14l2 8v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6z" /></svg>
);
export const IconRefresh = (p: IconProps) => (
  <svg {...S(p)}><path d="M21 12a9 9 0 11-3-6.7" /><path d="M21 4v4h-4" /></svg>
);
export const IconPlus = (p: IconProps) => (
  <svg {...S(p)}><path d="M12 5v14M5 12h14" /></svg>
);

/** Wrapper ikon bulat berwarna untuk stat card. */
export function StatIcon({ bg, color, children }: { bg: string; color: string; children: ReactNode }) {
  return (
    <span className="stat-icon" style={{ background: bg, color }}>
      {children}
    </span>
  );
}
