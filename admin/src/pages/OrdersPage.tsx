import { useCallback, useEffect, useState } from 'react';
import { api, fmtNumber, fmtRupiah, timeAgo } from '../api';
import { Card, EmptyState, ErrorState, Modal, Pagination, Spinner, StatCard, StatusPill, Thumb } from '../components';
import { Layout } from '../Layout';
import { IconCheck, IconClock, IconListings, IconWallet } from '../icons';

const ORDER_STATUSES = ['pending', 'accepted', 'processed', 'ready', 'completed', 'cancelled', 'rejected'];

export default function OrdersPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [detail, setDetail] = useState<any | null>(null);
  const [newStatus, setNewStatus] = useState('accepted');
  const limit = 10;

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api<any>('/admin/orders', { query: { page, limit, status } });
      setRows(res.orders);
      setTotal(res.total);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, [page, status]);

  useEffect(() => {
    load();
  }, [load]);

  async function changeStatus(id: string, s: string) {
    try {
      await api(`/admin/orders/${id}/status`, { method: 'PUT', body: { status: s } });
      setDetail(null);
      load();
    } catch (e: any) {
      alert(e.message);
    }
  }

  const revenue = rows
    .filter((o) => o.status === 'completed')
    .reduce((s, o) => s + o.totalAmount, 0);

  return (
    <Layout breadcrumb="Transactions" title="Transactions">
      <div className="stats-grid">
        <StatCard label="Total transaksi" value={fmtNumber(total)} icon={<IconListings size={17} />}
          iconBg="var(--info-bg)" iconColor="var(--primary)" />
        <StatCard label="Menunggu" value={fmtNumber(rows.filter((o) => o.status === 'pending').length)}
          icon={<IconClock size={17} />} iconBg="var(--warning-bg)" iconColor="#A16207" />
        <StatCard label="Selesai" value={fmtNumber(rows.filter((o) => o.status === 'completed').length)}
          icon={<IconCheck size={17} />} iconBg="var(--success-bg)" iconColor="var(--success)" />
        <StatCard label="Pendapatan (halaman ini)" value={fmtRupiah(revenue)} icon={<IconWallet size={17} />}
          iconBg="var(--danger-bg)" iconColor="var(--danger)" />
      </div>

      <Card>
        <div className="toolbar">
          <select className="select" value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
            <option value="">Semua status</option>
            {ORDER_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
        </div>

        {loading && <Spinner />}
        {!loading && error && <ErrorState message={error} onRetry={load} />}
        {!loading && !error && rows.length === 0 && (
          <EmptyState message="Tidak ada transaksi" icon={<IconListings />} />
        )}
        {!loading && !error && rows.length > 0 && (
          <>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Order</th>
                    <th>Produk</th>
                    <th>Pembeli</th>
                    <th>Penjual</th>
                    <th>Metode</th>
                    <th>Total</th>
                    <th>Status</th>
                    <th>Waktu</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {rows.map((o) => (
                    <tr key={o.id}>
                      <td className="cell-sub">#{o.id.slice(0, 8)}</td>
                      <td>
                        <div className="cell-product">
                          <Thumb src={o.items?.[0]?.product?.images?.[0]?.imageUrl} />
                          <div>
                            <div className="cell-strong">{o.items?.[0]?.product?.name ?? '-'}</div>
                            <div className="cell-sub">{o.items?.length ?? 0} item</div>
                          </div>
                        </div>
                      </td>
                      <td className="cell-sub">{o.buyer?.profile?.fullName ?? '-'}</td>
                      <td className="cell-sub">{o.seller?.profile?.fullName ?? '-'}</td>
                      <td style={{ textTransform: 'uppercase', fontSize: 11 }}>{o.deliveryMethod}</td>
                      <td className="cell-strong">{fmtRupiah(o.totalAmount)}</td>
                      <td><StatusPill status={o.status} /></td>
                      <td className="cell-sub">{timeAgo(o.createdAt)}</td>
                      <td>
                        <button className="btn btn-sm" onClick={() => { setDetail(o); setNewStatus(o.status); }}>
                          Detail
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
          title={`Order #${detail.id.slice(0, 8)}`}
          onClose={() => setDetail(null)}
          actions={
            <>
              <button className="btn" onClick={() => setDetail(null)}>Tutup</button>
              <button className="btn btn-primary" onClick={() => changeStatus(detail.id, newStatus)}>
                Ubah status
              </button>
            </>
          }
        >
          <div className="kv-list">
            <Row label="Pembeli" value={detail.buyer?.profile?.fullName ?? '-'} />
            <Row label="Penjual" value={detail.seller?.profile?.fullName ?? '-'} />
            <Row label="Metode" value={detail.deliveryMethod} />
            <Row label="Alamat" value={detail.deliveryAddress ?? '-'} />
            <Row label="Total" value={fmtRupiah(detail.totalAmount)} />
            <Row label="Status" value={<StatusPill status={detail.status} />} />
          </div>
          <div style={{ marginTop: 16 }}>
            <div className="cell-strong" style={{ marginBottom: 8 }}>Item</div>
            {detail.items?.map((it: any) => (
              <div className="kv" key={it.id}>
                <span className="kv-label">{it.product?.name} × {it.quantity}</span>
                <span className="kv-value">{fmtRupiah(it.subtotal)}</span>
              </div>
            ))}
          </div>
          <div className="form-group" style={{ marginTop: 16 }}>
            <label>Status baru (admin override)</label>
            <select className="select" value={newStatus} onChange={(e) => setNewStatus(e.target.value)}>
              {ORDER_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
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
