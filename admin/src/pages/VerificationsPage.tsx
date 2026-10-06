import { useCallback, useEffect, useState } from 'react';
import { api, fmtDate } from '../api';
import { Card, EmptyState, ErrorState, Modal, Spinner, StatCard, StatusPill } from '../components';
import { Layout } from '../Layout';
import { IconCheck, IconClock, IconUsers, IconX } from '../icons';

export default function VerificationsPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [tab, setTab] = useState<'pending' | 'approved' | 'rejected' | 'all'>('pending');
  const [detail, setDetail] = useState<any | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api<any>('/admin/verifications', {
        query: { limit: 50, ...(tab !== 'all' ? { status: tab } : {}) },
      });
      setRows(res.verifications);
      setTotal(res.total);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, [tab]);

  useEffect(() => {
    load();
  }, [load]);

  async function decide(id: string, status: 'approved' | 'rejected') {
    setBusy(true);
    try {
      await api(`/admin/verifications/${id}`, { method: 'PUT', body: { status } });
      setDetail(null);
      await load();
    } catch (e: any) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  const pendingCount = rows.filter((r) => r.status === 'pending').length;
  const approvedCount = rows.filter((r) => r.status === 'approved').length;
  const rejectedCount = rows.filter((r) => r.status === 'rejected').length;

  return (
    <Layout breadcrumb="Verification" title="Verification">
      <div className="stats-grid">
        <StatCard label="Pending" value={tab === 'pending' ? rows.length : pendingCount}
          icon={<IconClock size={17} />} iconBg="var(--info-bg)" iconColor="var(--primary)" />
        <StatCard label="Approved" value={tab === 'approved' ? rows.length : approvedCount}
          icon={<IconCheck size={17} />} iconBg="var(--success-bg)" iconColor="var(--success)" />
        <StatCard label="Rejected" value={tab === 'rejected' ? rows.length : rejectedCount}
          icon={<IconX size={17} />} iconBg="var(--danger-bg)" iconColor="var(--danger)" />
        <StatCard label="Total" value={total} icon={<IconUsers size={17} />}
          iconBg="#F1F5F9" iconColor="var(--text-secondary)" />
      </div>

      <Card
        title="Pengajuan Verifikasi Mahasiswa"
        subtitle="Tinjau dan putuskan pengajuan verifikasi"
        action={
          <div className="tabs" style={{ margin: 0 }}>
            {(['pending', 'approved', 'rejected', 'all'] as const).map((t) => (
              <button key={t} className={`tab ${tab === t ? 'active' : ''}`} onClick={() => setTab(t)}>
                {t === 'all' ? 'Semua' : t === 'pending' ? 'Pending' : t === 'approved' ? 'Approved' : 'Rejected'}
              </button>
            ))}
          </div>
        }
      >
        {loading && <Spinner />}
        {!loading && error && <ErrorState message={error} onRetry={load} />}
        {!loading && !error && rows.length === 0 && (
          <EmptyState message="Tidak ada pengajuan verifikasi" icon={<IconCheck />} />
        )}
        {!loading && !error && rows.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Mahasiswa</th>
                  <th>NIM / NIP</th>
                  <th>Kampus</th>
                  <th>Status</th>
                  <th>Diajukan</th>
                  <th>Ditinjau</th>
                  <th>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((v) => (
                  <tr key={v.id}>
                    <td>
                      <div className="cell-product">
                        <span className="avatar" style={{ width: 34, height: 34, borderRadius: 9 }}>
                          {(v.user?.profile?.fullName || v.user?.email || 'M').charAt(0).toUpperCase()}
                        </span>
                        <div>
                          <div className="cell-strong">{v.user?.profile?.fullName ?? '-'}</div>
                          <div className="cell-sub">{v.user?.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="cell-strong">{v.studentIdentifier}</td>
                    <td>{v.campus?.name ?? '-'}</td>
                    <td><StatusPill status={v.status} /></td>
                    <td className="cell-sub">{fmtDate(v.createdAt)}</td>
                    <td className="cell-sub">{v.reviewedAt ? fmtDate(v.reviewedAt) : '-'}</td>
                    <td>
                      {v.status === 'pending' ? (
                        <button className="btn btn-sm btn-primary" onClick={() => setDetail(v)}>
                          Review
                        </button>
                      ) : (
                        <span className="cell-sub">Selesai</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {detail && (
        <Modal
          title="Review Verifikasi"
          onClose={() => setDetail(null)}
          actions={
            <>
              <button className="btn" onClick={() => setDetail(null)} disabled={busy}>Tutup</button>
              <button className="btn btn-danger" disabled={busy}
                onClick={() => decide(detail.id, 'rejected')}>
                <IconX size={14} /> Tolak
              </button>
              <button className="btn btn-success" disabled={busy}
                onClick={() => decide(detail.id, 'approved')}>
                <IconCheck size={14} /> Setujui
              </button>
            </>
          }
        >
          <div className="kv-list">
            <Row label="Nama" value={detail.user?.profile?.fullName ?? '-'} />
            <Row label="Email" value={detail.user?.email ?? '-'} />
            <Row label="NIM / NIP" value={detail.studentIdentifier} />
            <Row label="Kampus" value={detail.campus?.name ?? '-'} />
            <Row label="Kota" value={detail.campus?.city ?? '-'} />
            <Row label="Dokumen" value={detail.document ?? 'Tidak ada dokumen'} />
            <Row label="Tanggal pengajuan" value={fmtDate(detail.createdAt)} />
          </div>
        </Modal>
      )}
    </Layout>
  );
}

function Row({ label, value }: { label: string; value: any }) {
  return (
    <div className="kv">
      <span className="kv-label">{label}</span>
      <span className="kv-value">{value}</span>
    </div>
  );
}
