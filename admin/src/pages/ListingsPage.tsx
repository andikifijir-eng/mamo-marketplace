import { useCallback, useEffect, useState } from 'react';
import { api, fmtNumber, fmtRupiah, timeAgo } from '../api';
import { Card, EmptyState, ErrorState, Modal, Pagination, Spinner, StatCard, StatusPill, Thumb } from '../components';
import { Layout } from '../Layout';
import { IconCheck, IconListings, IconStore, IconX } from '../icons';

const PRODUCT_STATUSES = ['active', 'flagged', 'rejected', 'sold', 'archived', 'draft'];

export default function ListingsPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [detail, setDetail] = useState<any | null>(null);
  const [newStatus, setNewStatus] = useState('active');
  const limit = 10;

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api<any>('/admin/products', { query: { page, limit, search, status } });
      setRows(res.products);
      setTotal(res.total);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, [page, search, status]);

  useEffect(() => {
    load();
  }, [load]);

  async function changeStatus(id: string, s: string) {
    try {
      await api(`/admin/products/${id}/status`, { method: 'PUT', body: { status: s } });
      setDetail(null);
      load();
    } catch (e: any) {
      alert(e.message);
    }
  }

  return (
    <Layout breadcrumb="Listings" title="Listings">
      <div className="stats-grid">
        <StatCard label="Total listings" value={fmtNumber(total)} icon={<IconListings size={17} />}
          iconBg="var(--info-bg)" iconColor="var(--primary)" />
        <StatCard label="Aktif" value={fmtNumber(rows.filter((r) => r.status === 'active').length)}
          icon={<IconCheck size={17} />} iconBg="var(--success-bg)" iconColor="var(--success)" />
        <StatCard label="Terjual" value={fmtNumber(rows.filter((r) => r.status === 'sold').length)}
          icon={<IconStore size={17} />} iconBg="var(--warning-bg)" iconColor="#A16207" />
        <StatCard label="Flagged" value={fmtNumber(rows.filter((r) => r.status === 'flagged').length)}
          icon={<IconX size={17} />} iconBg="var(--danger-bg)" iconColor="var(--danger)" />
      </div>

      <Card>
        <div className="toolbar">
          <input className="input input-search" placeholder="Cari judul listing atau penjual"
            value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
          <select className="select" value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
            <option value="">Semua status</option>
            {PRODUCT_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
        </div>

        {loading && <Spinner />}
        {!loading && error && <ErrorState message={error} onRetry={load} />}
        {!loading && !error && rows.length === 0 && (
          <EmptyState message="Tidak ada listing" icon={<IconListings />} />
        )}
        {!loading && !error && rows.length > 0 && (
          <>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Listing</th>
                    <th>Kategori</th>
                    <th>Harga</th>
                    <th>Lokasi</th>
                    <th>Status</th>
                    <th>Favorit</th>
                    <th>Dibuat</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {rows.map((p) => (
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
                      <td>{p._count?.favorites ?? 0}</td>
                      <td className="cell-sub">{timeAgo(p.createdAt)}</td>
                      <td>
                        <button className="btn btn-sm" onClick={() => { setDetail(p); setNewStatus(p.status); }}>
                          Moderasi
                        </button>
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
          title="Moderasi Listing"
          onClose={() => setDetail(null)}
          actions={
            <>
              <button className="btn" onClick={() => setDetail(null)}>Batal</button>
              <button className="btn btn-primary" onClick={() => changeStatus(detail.id, newStatus)}>
                Simpan status
              </button>
            </>
          }
        >
          <div className="cell-product" style={{ marginBottom: 16 }}>
            <Thumb src={detail.images?.[0]?.imageUrl} />
            <div>
              <div className="cell-strong">{detail.name}</div>
              <div className="cell-sub">{detail.seller?.email}</div>
            </div>
          </div>
          <div className="kv-list">
            <Row label="Harga" value={fmtRupiah(detail.price)} />
            <Row label="Stok" value={`${detail.stock}`} />
            <Row label="Kondisi" value={detail.condition === 'new' ? 'Baru' : 'Bekas'} />
            <Row label="Kategori" value={detail.category?.name ?? '-'} />
            <Row label="Lokasi" value={detail.location ?? '-'} />
            <Row label="Favorit" value={`${detail._count?.favorites ?? 0}`} />
            <Row label="Jumlah report" value={`${detail._count?.reports ?? 0}`} />
          </div>
          {detail.description && (
            <p style={{ fontSize: 12.5, color: 'var(--text-secondary)', lineHeight: 1.6, marginTop: 14 }}>
              {detail.description}
            </p>
          )}
          <div className="form-group" style={{ marginTop: 16 }}>
            <label>Ubah status listing</label>
            <select className="select" value={newStatus} onChange={(e) => setNewStatus(e.target.value)}>
              {PRODUCT_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
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
