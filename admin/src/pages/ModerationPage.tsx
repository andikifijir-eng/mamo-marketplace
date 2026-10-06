import { useCallback, useEffect, useState } from 'react';
import { api, fmtNumber, fmtRupiah, timeAgo } from '../api';
import { Card, EmptyState, ErrorState, Spinner, StatCard, StatusPill, Thumb } from '../components';
import { Layout } from '../Layout';
import { IconCheck, IconClock, IconFlag, IconX } from '../icons';

export default function ModerationPage() {
  const [flagged, setFlagged] = useState<any[]>([]);
  const [pending, setPending] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [tab, setTab] = useState<'all' | 'flagged' | 'pending'>('all');
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [f, p] = await Promise.all([
        api<any>('/admin/products', { query: { status: 'flagged', limit: 50 } }),
        api<any>('/admin/products', { query: { status: 'draft', limit: 50 } }),
      ]);
      setFlagged(f.products);
      setPending(p.products);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function decide(id: string, status: 'active' | 'rejected') {
    setBusyId(id);
    try {
      await api(`/admin/products/${id}/status`, { method: 'PUT', body: { status } });
      await load();
    } catch (e: any) {
      alert(e.message);
    } finally {
      setBusyId(null);
    }
  }

  const all = [...flagged, ...pending];
  const shown = tab === 'flagged' ? flagged : tab === 'pending' ? pending : all;

  return (
    <Layout breadcrumb="Moderation Queue" title="Moderation Queue">
      <div className="stats-grid">
        <StatCard label="High risk (flagged)" value={fmtNumber(flagged.length)} icon={<IconFlag size={17} />}
          iconBg="var(--danger-bg)" iconColor="var(--danger)" trend="Perlu review" trendUp={false} />
        <StatCard label="Pending review" value={fmtNumber(pending.length)} icon={<IconClock size={17} />}
          iconBg="var(--info-bg)" iconColor="var(--primary)" trend="Dalam SLA" trendUp />
        <StatCard label="Total antrian" value={fmtNumber(all.length)} icon={<IconCheck size={17} />}
          iconBg="var(--success-bg)" iconColor="var(--success)" />
      </div>

      <Card
        title="Moderation Queue"
        subtitle="Listing yang perlu perhatian segera"
        action={
          <div className="tabs" style={{ margin: 0 }}>
            <button className={`tab ${tab === 'all' ? 'active' : ''}`} onClick={() => setTab('all')}>Semua</button>
            <button className={`tab ${tab === 'flagged' ? 'active' : ''}`} onClick={() => setTab('flagged')}>
              Flagged ({flagged.length})
            </button>
            <button className={`tab ${tab === 'pending' ? 'active' : ''}`} onClick={() => setTab('pending')}>
              Pending ({pending.length})
            </button>
          </div>
        }
      >
        {loading && <Spinner />}
        {!loading && error && <ErrorState message={error} onRetry={load} />}
        {!loading && !error && shown.length === 0 && (
          <EmptyState message="Antrian moderasi bersih. Tidak ada listing bermasalah."
            icon={<IconCheck />} />
        )}
        {!loading && !error && shown.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Listing</th>
                  <th>Kategori</th>
                  <th>Harga</th>
                  <th>Lokasi</th>
                  <th>Status</th>
                  <th>Diajukan</th>
                  <th>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {shown.map((p) => (
                  <tr key={p.id}>
                    <td>
                      <div className="cell-product">
                        <Thumb src={p.images?.[0]?.imageUrl} />
                        <div>
                          <div className="cell-strong">{p.name}</div>
                          <div className="cell-sub">{p.seller?.profile?.fullName ?? '-'}</div>
                        </div>
                      </div>
                    </td>
                    <td>{p.category?.name ?? '-'}</td>
                    <td>{fmtRupiah(p.price)}</td>
                    <td>{p.location ?? '-'}</td>
                    <td><StatusPill status={p.status} /></td>
                    <td className="cell-sub">{timeAgo(p.createdAt)}</td>
                    <td>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button
                          className="btn btn-sm btn-success"
                          disabled={busyId === p.id}
                          onClick={() => decide(p.id, 'active')}
                        >
                          <IconCheck size={13} /> Setujui
                        </button>
                        <button
                          className="btn btn-sm btn-danger"
                          disabled={busyId === p.id}
                          onClick={() => decide(p.id, 'rejected')}
                        >
                          <IconX size={13} /> Tolak
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
