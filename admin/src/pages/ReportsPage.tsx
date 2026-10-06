import { useCallback, useEffect, useState } from 'react';
import { api, fmtNumber, timeAgo } from '../api';
import { Card, EmptyState, ErrorState, Pill, Spinner, StatCard, StatusPill, Thumb } from '../components';
import { Layout } from '../Layout';
import { IconCheck, IconClock, IconFlag, IconX } from '../icons';

const REASONS = ['suspected_scam', 'duplicate', 'misleading', 'prohibited', 'other'];

export default function ReportsPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [tab, setTab] = useState<'all' | 'open' | 'resolved'>('all');
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api<any>('/reports', { query: { limit: 50 } });
      setRows(res.reports);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function resolve(id: string, status: 'resolved' | 'rejected') {
    setBusyId(id);
    try {
      await api(`/reports/${id}`, { method: 'PUT', body: { status } });
      await load();
    } catch (e: any) {
      alert(e.message);
    } finally {
      setBusyId(null);
    }
  }

  const open = rows.filter((r) => r.status === 'open');
  const resolved = rows.filter((r) => r.status === 'resolved');
  const rejected = rows.filter((r) => r.status === 'rejected');
  const shown = tab === 'open' ? open : tab === 'resolved' ? resolved : rows;

  return (
    <Layout breadcrumb="Reports" title="Reports">
      <div className="stats-grid">
        <StatCard label="Total reports" value={fmtNumber(rows.length)} icon={<IconFlag size={17} />}
          iconBg="var(--danger-bg)" iconColor="var(--danger)" />
        <StatCard label="New / open" value={fmtNumber(open.length)} icon={<IconClock size={17} />}
          iconBg="var(--info-bg)" iconColor="var(--primary)" />
        <StatCard label="Resolved" value={fmtNumber(resolved.length)} icon={<IconCheck size={17} />}
          iconBg="var(--success-bg)" iconColor="var(--success)" />
        <StatCard label="Rejected" value={fmtNumber(rejected.length)} icon={<IconX size={17} />}
          iconBg="#F1F5F9" iconColor="var(--text-secondary)" />
      </div>

      <Card
        title="Laporan Pengguna"
        subtitle="Laporan listing dari pembeli"
        action={
          <div className="tabs" style={{ margin: 0 }}>
            <button className={`tab ${tab === 'all' ? 'active' : ''}`} onClick={() => setTab('all')}>Semua</button>
            <button className={`tab ${tab === 'open' ? 'active' : ''}`} onClick={() => setTab('open')}>
              Open ({open.length})
            </button>
            <button className={`tab ${tab === 'resolved' ? 'active' : ''}`} onClick={() => setTab('resolved')}>
              Resolved ({resolved.length})
            </button>
          </div>
        }
      >
        {loading && <Spinner />}
        {!loading && error && <ErrorState message={error} onRetry={load} />}
        {!loading && !error && shown.length === 0 && (
          <EmptyState message="Tidak ada laporan" icon={<IconCheck />} />
        )}
        {!loading && !error && shown.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Report</th>
                  <th>Listing dilaporkan</th>
                  <th>Pelapor</th>
                  <th>Alasan</th>
                  <th>Status</th>
                  <th>Dilaporkan</th>
                  <th>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {shown.map((r) => (
                  <tr key={r.id}>
                    <td className="cell-sub">RPT-{r.id.slice(0, 6).toUpperCase()}</td>
                    <td>
                      <div className="cell-product">
                        <Thumb src={r.product?.images?.[0]?.imageUrl} />
                        <div>
                          <div className="cell-strong">{r.product?.name ?? '(produk dihapus)'}</div>
                          <div className="cell-sub">Pelapor: {r.reporter?.profile?.fullName ?? '-'}</div>
                        </div>
                      </div>
                    </td>
                    <td className="cell-sub">{r.reporter?.email ?? '-'}</td>
                    <td>
                      <div className="cell-strong" style={{ fontSize: 12 }}>
                        {r.reason.replace(/_/g, ' ')}
                      </div>
                      {r.detail && <div className="cell-sub">{r.detail}</div>}
                    </td>
                    <td><StatusPill status={r.status} /></td>
                    <td className="cell-sub">{timeAgo(r.createdAt)}</td>
                    <td>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button className="btn btn-sm btn-success" disabled={busyId === r.id}
                          onClick={() => resolve(r.id, 'resolved')}>
                          Resolve
                        </button>
                        <button className="btn btn-sm" disabled={busyId === r.id}
                          onClick={() => resolve(r.id, 'rejected')}>
                          Abaikan
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </Layout>
  );
}
