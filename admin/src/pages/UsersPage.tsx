import { useCallback, useEffect, useState } from 'react';
import { api, fmtNumber, fmtDate } from '../api';
import { Card, EmptyState, ErrorState, Modal, Pagination, Pill, Spinner, StatCard, StatusPill } from '../components';
import { Layout } from '../Layout';
import { IconCheck, IconSearch, IconUsers, IconX } from '../icons';

export default function UsersPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [detail, setDetail] = useState<any | null>(null);
  const limit = 10;

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api<any>('/admin/users', {
        query: { page, limit, search, role, status },
      });
      setRows(res.users);
      setTotal(res.total);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, [page, search, role, status]);

  useEffect(() => {
    load();
  }, [load]);

  async function setAccountStatus(userId: string, accountStatus: string) {
    try {
      await api(`/admin/users/${userId}/status`, { method: 'PUT', body: { accountStatus } });
      load();
      setDetail(null);
    } catch (e: any) {
      alert(e.message);
    }
  }

  const activeCount = rows.filter((u) => u.accountStatus === 'active').length;
  const bannedCount = rows.filter((u) => u.accountStatus !== 'active').length;

  return (
    <Layout breadcrumb="Users" title="Users">
      <div className="stats-grid">
        <StatCard label="Total users" value={fmtNumber(total)} icon={<IconUsers size={17} />}
          iconBg="var(--info-bg)" iconColor="var(--primary)" />
        <StatCard label="Aktif (halaman ini)" value={fmtNumber(activeCount)} icon={<IconCheck size={17} />}
          iconBg="var(--success-bg)" iconColor="var(--success)" />
        <StatCard label="Dibatasi (halaman ini)" value={fmtNumber(bannedCount)} icon={<IconX size={17} />}
          iconBg="var(--danger-bg)" iconColor="var(--danger)" />
      </div>

      <Card>
        <div className="toolbar">
          <input
            className="input input-search"
            placeholder="Cari nama, email, atau user ID"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          />
          <select className="select" value={role} onChange={(e) => { setRole(e.target.value); setPage(1); }}>
            <option value="">Semua role</option>
            <option value="buyer">Buyer</option>
            <option value="seller">Seller</option>
            <option value="admin">Admin</option>
          </select>
          <select className="select" value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
            <option value="">Semua status</option>
            <option value="active">Aktif</option>
            <option value="suspended">Suspended</option>
            <option value="banned">Banned</option>
          </select>
        </div>

        {loading && <Spinner />}
        {!loading && error && <ErrorState message={error} onRetry={load} />}
        {!loading && !error && rows.length === 0 && (
          <EmptyState message="Tidak ada user yang cocok" icon={<IconUsers />} />
        )}
        {!loading && !error && rows.length > 0 && (
          <>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Verification</th>
                    <th>Listings</th>
                    <th>Orders</th>
                    <th>Joined</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {rows.map((u) => (
                    <tr key={u.id}>
                      <td>
                        <div className="cell-product">
                          <span className="avatar" style={{ width: 34, height: 34, borderRadius: 9, background: 'linear-gradient(135deg,#6366F1,#8B5CF6)' }}>
                            {(u.profile?.fullName || u.email).charAt(0).toUpperCase()}
                          </span>
                          <div>
                            <div className="cell-strong">{u.profile?.fullName ?? '-'}</div>
                            <div className="cell-sub">{u.email}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ textTransform: 'capitalize' }}>{u.role}</td>
                      <td><StatusPill status={u.accountStatus} /></td>
                      <td><StatusPill status={u.verifications?.[0]?.status ?? 'none'} /></td>
                      <td>{u._count?.products ?? 0}</td>
                      <td>{u._count?.buyerOrders ?? 0}</td>
                      <td className="cell-sub">{fmtDate(u.createdAt)}</td>
                      <td>
                        <button className="btn btn-sm" onClick={() => setDetail(u)}>Detail</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <Pagination page={page} total={total} limit={limit} onChange={setPage} />
          </>
        )}
      </Card>

      {detail && (
        <Modal
          title={detail.profile?.fullName ?? detail.email}
          onClose={() => setDetail(null)}
          actions={
            <>
              <button className="btn" onClick={() => setDetail(null)}>Tutup</button>
              {detail.accountStatus !== 'active' ? (
                <button className="btn btn-success" onClick={() => setAccountStatus(detail.id, 'active')}>
                  Aktifkan
                </button>
              ) : (
                <>
                  <button className="btn" onClick={() => setAccountStatus(detail.id, 'suspended')}>Suspend</button>
                  <button className="btn btn-danger" onClick={() => setAccountStatus(detail.id, 'banned')}>Ban</button>
                </>
              )}
            </>
          }
        >
          <div className="kv-list">
            <Row label="Email" value={detail.email} />
            <Row label="Role" value={detail.role} />
            <Row label="Status akun" value={<StatusPill status={detail.accountStatus} />} />
            <Row label="No. HP" value={detail.profile?.phone ?? '-'} />
            <Row label="Bio" value={detail.profile?.bio ?? '-'} />
            <Row label="Total listing" value={`${detail._count?.products ?? 0}`} />
            <Row label="Order sebagai buyer" value={`${detail._count?.buyerOrders ?? 0}`} />
            <Row label="Order sebagai seller" value={`${detail._count?.sellerOrders ?? 0}`} />
            <Row label="Ulasan diterima" value={`${detail._count?.reviewsReceived ?? 0}`} />
            <Row label="Terdaftar" value={fmtDate(detail.createdAt)} />
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
