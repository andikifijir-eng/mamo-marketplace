import type { ReactNode } from 'react';

type PillKind = 'green' | 'red' | 'blue' | 'amber' | 'gray' | 'purple';

export function Pill({ kind, children, icon }: { kind: PillKind; children: ReactNode; icon?: ReactNode }) {
  return (
    <span className={`pill pill-${kind}`}>
      {icon}
      {children}
    </span>
  );
}

/** Pill untuk status produk/order/verifikasi (nama status sama dengan backend). */
export function StatusPill({ status }: { status: string }) {
  const map: Record<string, { kind: PillKind; label: string }> = {
    // produk
    active: { kind: 'green', label: 'Aktif' },
    sold: { kind: 'amber', label: 'Terjual' },
    draft: { kind: 'gray', label: 'Draft' },
    archived: { kind: 'gray', label: 'Diarsipkan' },
    flagged: { kind: 'red', label: 'Flagged' },
    rejected: { kind: 'red', label: 'Ditolak' },
    // order
    pending: { kind: 'blue', label: 'Menunggu' },
    accepted: { kind: 'blue', label: 'Diterima' },
    processed: { kind: 'purple', label: 'Diproses' },
    ready: { kind: 'amber', label: 'Siap' },
    completed: { kind: 'green', label: 'Selesai' },
    cancelled: { kind: 'gray', label: 'Dibatalkan' },
    // akun
    suspended: { kind: 'amber', label: 'Suspended' },
    banned: { kind: 'red', label: 'Banned' },
    // verifikasi
    approved: { kind: 'green', label: 'Approved' },
    none: { kind: 'gray', label: 'Belum' },
    // report
    open: { kind: 'red', label: 'Open' },
    resolved: { kind: 'green', label: 'Resolved' },
  };
  const it = map[status] ?? { kind: 'gray' as PillKind, label: status };
  return <Pill kind={it.kind}>{it.label}</Pill>;
}

export function Spinner() {
  return <div className="spinner" />;
}

export function EmptyState({ message = 'Belum ada data', icon }: { message?: string; icon?: ReactNode }) {
  return (
    <div className="state">
      {icon && <div className="state-icon">{icon}</div>}
      <div>{message}</div>
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="state">
      <div className="state-icon" style={{ background: 'var(--danger-bg)', color: 'var(--danger)' }}>
        !
      </div>
      <div style={{ marginBottom: 14 }}>{message}</div>
      {onRetry && (
        <button className="btn" onClick={onRetry}>
          Coba lagi
        </button>
      )}
    </div>
  );
}

export function Card({
  title,
  subtitle,
  action,
  children,
  style,
}: {
  title?: string;
  subtitle?: string;
  action?: ReactNode;
  children: ReactNode;
  style?: React.CSSProperties;
}) {
  return (
    <div className="card" style={style}>
      {(title || action) && (
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'flex-start',
            marginBottom: 16,
            gap: 12,
          }}
        >
          <div>
            {title && <h3 className="card-title">{title}</h3>}
            {subtitle && <p className="card-sub">{subtitle}</p>}
          </div>
          {action}
        </div>
      )}
      {children}
    </div>
  );
}

export function StatCard({
  label,
  value,
  icon,
  iconBg,
  iconColor,
  trend,
  trendUp,
}: {
  label: string;
  value: ReactNode;
  icon: ReactNode;
  iconBg: string;
  iconColor: string;
  trend?: string;
  trendUp?: boolean;
}) {
  return (
    <div className="stat-card">
      <div className="stat-head">
        <span className="stat-icon" style={{ background: iconBg, color: iconColor }}>
          {icon}
        </span>
        {trend && (
          <span className={`stat-trend ${trendUp ? 'trend-up' : 'trend-down'}`}>{trend}</span>
        )}
      </div>
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
    </div>
  );
}

export function Pagination({
  page,
  total,
  limit,
  onChange,
}: {
  page: number;
  total: number;
  limit: number;
  onChange: (p: number) => void;
}) {
  const pages = Math.max(1, Math.ceil(total / limit));
  const shown = Math.min(limit, Math.max(0, total - (page - 1) * limit));
  const nums: number[] = [];
  for (let i = Math.max(1, page - 2); i <= Math.min(pages, page + 2); i++) nums.push(i);

  return (
    <div className="pagination">
      <span>
        Menampilkan {shown} dari {total.toLocaleString('id-ID')} data
      </span>
      <div className="page-btns">
        <button className="page-btn" disabled={page <= 1} onClick={() => onChange(page - 1)}>
          ‹
        </button>
        {nums.map((n) => (
          <button
            key={n}
            className={`page-btn ${n === page ? 'active' : ''}`}
            onClick={() => onChange(n)}
          >
            {n}
          </button>
        ))}
        <button className="page-btn" disabled={page >= pages} onClick={() => onChange(page + 1)}>
          ›
        </button>
      </div>
    </div>
  );
}

export function Thumb({ src, alt }: { src?: string | null; alt?: string }) {
  if (src) return <img className="thumb" src={src} alt={alt || ''} />;
  return (
    <span className="thumb">
      <IconImageSmall />
    </span>
  );
}

const IconImageSmall = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
    <rect x="3" y="4" width="18" height="16" rx="2" />
    <circle cx="9" cy="10" r="1.6" />
    <path d="M3 17l5-5 4 4 3-3 6 6" />
  </svg>
);

/** Modal konfirmasi / form generik. */
export function Modal({
  title,
  children,
  onClose,
  actions,
}: {
  title: string;
  children: ReactNode;
  onClose: () => void;
  actions?: ReactNode;
}) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h3>{title}</h3>
        {children}
        {actions && <div className="modal-actions">{actions}</div>}
      </div>
    </div>
  );
}
