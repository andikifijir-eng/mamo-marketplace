import { useEffect, useState } from 'react';
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { api, fmtNumber, fmtRupiah, timeAgo } from '../api';
import { Card, ErrorState, Spinner, StatCard, StatusPill, Thumb } from '../components';
import { Layout } from '../Layout';
import { IconBox, IconCheck, IconClock, IconUsers, IconWallet } from '../icons';

type Dash = {
  totalUsers: number;
  activeUsers: number;
  totalProducts: number;
  activeProducts: number;
  totalOrders: number;
  completedOrders: number;
  pendingVerifications: number;
  openReports: number;
  revenue: number;
  chart7Days: { date: string; orders: number; revenue: number }[];
  recentActivities: any[];
};

export default function DashboardPage() {
  const [data, setData] = useState<Dash | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    setError('');
    try {
      setData(await api<Dash>('/admin/dashboard'));
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  return (
    <Layout breadcrumb="Dashboard" title="Dashboard">
      {loading && <Spinner />}
      {!loading && error && <ErrorState message={error} onRetry={load} />}
      {!loading && data && (
        <>
          <div className="stats-grid">
            <StatCard
              label="Pending review"
              value={fmtNumber(data.pendingVerifications)}
              icon={<IconClock size={17} />}
              iconBg="var(--warning-bg)"
              iconColor="#A16207"
              trend={`${data.openReports} laporan terbuka`}
              trendUp={false}
            />
            <StatCard
              label="Active listings"
              value={fmtNumber(data.activeProducts)}
              icon={<IconCheck size={17} />}
              iconBg="var(--success-bg)"
              iconColor="var(--success)"
              trend={`dari ${fmtNumber(data.totalProducts)} listing`}
              trendUp
            />
            <StatCard
              label="Active users"
              value={fmtNumber(data.activeUsers)}
              icon={<IconUsers size={17} />}
              iconBg="#FAE8FF"
              iconColor="#A21CAF"
              trend={`dari ${fmtNumber(data.totalUsers)} user`}
              trendUp
            />
            <StatCard
              label="Total revenue"
              value={fmtRupiah(data.revenue)}
              icon={<IconWallet size={17} />}
              iconBg="var(--danger-bg)"
              iconColor="var(--danger)"
              trend={`${fmtNumber(data.completedOrders)} order selesai`}
              trendUp
            />
          </div>

          <div className="grid-2">
            <Card title="Marketplace overview" subtitle="Pesanan & pendapatan 7 hari terakhir">
              <div style={{ height: 260 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={data.chart7Days}>
                    <defs>
                      <linearGradient id="gradRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#3B5BFF" stopOpacity={0.32} />
                        <stop offset="100%" stopColor="#3B5BFF" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#EDF1F5" vertical={false} />
                    <XAxis
                      dataKey="date"
                      tickFormatter={(v) => v.slice(5)}
                      tick={{ fontSize: 11, fill: '#9CA3AF' }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <YAxis
                      tickFormatter={(v) => (v >= 1000 ? `${v / 1000}k` : v)}
                      tick={{ fontSize: 11, fill: '#9CA3AF' }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <Tooltip
                      formatter={(v: any) => fmtRupiah(Number(v))}
                      labelFormatter={(l) => `Tanggal ${l}`}
                      contentStyle={{ borderRadius: 10, border: '1px solid #EDF1F5', fontSize: 12 }}
                    />
                    <Area
                      type="monotone"
                      dataKey="revenue"
                      stroke="#3B5BFF"
                      strokeWidth={2.5}
                      fill="url(#gradRevenue)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card title="Recent activities" subtitle="Aktivitas transaksi terbaru">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                {data.recentActivities.length === 0 && (
                  <p className="card-sub">Belum ada aktivitas.</p>
                )}
                {data.recentActivities.map((o) => (
                  <div key={o.id} style={{ display: 'flex', gap: 11, alignItems: 'flex-start' }}>
                    <span
                      style={{
                        width: 32, height: 32, borderRadius: 9, flexShrink: 0,
                        display: 'grid', placeItems: 'center',
                        background: o.status === 'completed' ? 'var(--success-bg)' : 'var(--info-bg)',
                        color: o.status === 'completed' ? 'var(--success)' : 'var(--primary)',
                      }}
                    >
                      <IconBox size={15} />
                    </span>
                    <div style={{ minWidth: 0, flex: 1 }}>
                      <div style={{ fontSize: 12.5, fontWeight: 600 }}>
                        {o.buyer?.profile?.fullName ?? 'Buyer'} → {o.seller?.profile?.fullName ?? 'Seller'}
                      </div>
                      <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                        {fmtRupiah(o.totalAmount)} · {timeAgo(o.createdAt)}
                      </div>
                    </div>
                    <StatusPill status={o.status} />
                  </div>
                ))}
              </div>
            </Card>
          </div>

          <ModerationPreview />
        </>
      )}
    </Layout>
  );
}

function ModerationPreview() {
  const [items, setItems] = useState<any[]>([]);

  useEffect(() => {
    api<any>('/admin/products', { query: { limit: 4, status: 'flagged' } })
      .then((r) => setItems(r.products))
      .catch(() => {});
  }, []);

  return (
    <Card
      title="Moderation Queue"
      subtitle="Listing yang butuh perhatian segera"
      action={
        <a href="/moderation" className="btn btn-sm">
          Lihat semua
        </a>
      }
      style={{ marginTop: 4 }}
    >
      {items.length === 0 ? (
        <p className="card-sub">Tidak ada listing yang perlu dimoderasi.</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Listing</th>
                <th>Kategori</th>
                <th>Harga</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {items.map((p) => (
                <tr key={p.id}>
                  <td>
                    <div className="cell-product">
                      <Thumb src={p.images?.[0]?.imageUrl} />
                      <div>
                        <div className="cell-strong">{p.name}</div>
                        <div className="cell-sub">{p.seller?.profile?.fullName}</div>
                      </div>
                    </div>
                  </td>
                  <td>{p.category?.name ?? '-'}</td>
                  <td>{fmtRupiah(p.price)}</td>
                  <td>
                    <StatusPill status={p.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
