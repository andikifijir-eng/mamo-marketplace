import { useEffect, useState } from 'react';
import { Bar, BarChart, CartesianGrid, Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { api, fmtNumber, fmtRupiah } from '../api';
import { Card, ErrorState, Spinner } from '../components';
import { Layout } from '../Layout';

const COLORS = ['#3B5BFF', '#8B5CF6', '#22C55E', '#FACC15', '#EF4444'];

export default function AnalyticsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [orders, setOrders] = useState<any[]>([]);
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function load() {
    setLoading(true);
    setError('');
    try {
      const [p, o, u] = await Promise.all([
        api<any>('/admin/products', { query: { limit: 100 } }),
        api<any>('/admin/orders', { query: { limit: 100 } }),
        api<any>('/admin/users', { query: { limit: 100 } }),
      ]);
      setProducts(p.products);
      setOrders(o.orders);
      setUsers(u.users);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  // Agregasi kategori dari data nyata
  const catMap = new Map<string, number>();
  products.forEach((p) => {
    const name = p.category?.name ?? 'Tanpa kategori';
    catMap.set(name, (catMap.get(name) ?? 0) + 1);
  });
  const topCategories = [...catMap.entries()]
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 6);

  // Distribusi status order
  const statusMap = new Map<string, number>();
  orders.forEach((o) => statusMap.set(o.status, (statusMap.get(o.status) ?? 0) + 1));
  const orderStatusData = [...statusMap.entries()].map(([name, value]) => ({ name, value }));

  // Pertumbuhan 7 hari (order per hari)
  const growth: { date: string; orders: number; revenue: number }[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000).toISOString().slice(0, 10);
    const dayOrders = orders.filter((o) => (o.createdAt ?? '').slice(0, 10) === d);
    growth.push({
      date: d.slice(5),
      orders: dayOrders.length,
      revenue: dayOrders.reduce((s, o) => s + (o.totalAmount ?? 0), 0),
    });
  }

  const totalCompleted = orders.filter((o) => o.status === 'completed');
  const revenue = totalCompleted.reduce((s, o) => s + o.totalAmount, 0);
  const acceptRate = orders.length
    ? Math.round((orders.filter((o) => o.status !== 'rejected' && o.status !== 'cancelled').length / orders.length) * 100)
    : 0;

  return (
    <Layout breadcrumb="Analytics" title="Analytics">
      {loading && <Spinner />}
      {!loading && error && <ErrorState message={error} onRetry={load} />}
      {!loading && !error && (
        <>
          <div className="grid-3" style={{ marginBottom: 18 }}>
            <Card title="Marketplace growth" subtitle="Pesanan 7 hari terakhir">
              <div style={{ height: 230 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={growth}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#EDF1F5" vertical={false} />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} allowDecimals={false} />
                    <Tooltip contentStyle={{ borderRadius: 10, border: '1px solid #EDF1F5', fontSize: 12 }} />
                    <Bar dataKey="orders" fill="#3B5BFF" radius={[5, 5, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card title="Order outcomes" subtitle={`${orders.length} transaksi total`}>
              <div style={{ height: 230 }}>
                {orderStatusData.length === 0 ? (
                  <p className="card-sub">Belum ada transaksi.</p>
                ) : (
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={orderStatusData}
                        dataKey="value"
                        nameKey="name"
                        innerRadius={52}
                        outerRadius={82}
                        paddingAngle={3}
                      >
                        {orderStatusData.map((_, i) => (
                          <Cell key={i} fill={COLORS[i % COLORS.length]} />
                        ))}
                      </Pie>
                      <Legend wrapperStyle={{ fontSize: 11 }} />
                      <Tooltip contentStyle={{ borderRadius: 10, border: '1px solid #EDF1F5', fontSize: 12 }} />
                    </PieChart>
                  </ResponsiveContainer>
                )}
              </div>
            </Card>

            <Card title="Top categories" subtitle="Berdasarkan jumlah listing">
              <div style={{ marginTop: 4 }}>
                {topCategories.length === 0 && <p className="card-sub">Belum ada kategori terpakai.</p>}
                {topCategories.map((c, i) => {
                  const max = topCategories[0]?.value || 1;
                  return (
                    <div className="bar-row" key={c.name}>
                      <div className="bar-head">
                        <span style={{ fontWeight: 600 }}>{c.name}</span>
                        <span style={{ color: 'var(--text-secondary)' }}>{fmtNumber(c.value)}</span>
                      </div>
                      <div className="bar-track">
                        <div
                          className="bar-fill"
                          style={{ width: `${(c.value / max) * 100}%`, background: COLORS[i % COLORS.length] }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>
          </div>

          <div className="grid-2">
            <Card title="Revenue trend" subtitle="Pendapatan dari order selesai, 7 hari">
              <div style={{ height: 220 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={growth}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#EDF1F5" vertical={false} />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#9CA3AF' }} axisLine={false} tickLine={false} />
                    <YAxis
                      tickFormatter={(v) => (v >= 1000 ? `${v / 1000}k` : v)}
                      tick={{ fontSize: 11, fill: '#9CA3AF' }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <Tooltip formatter={(v: any) => fmtRupiah(Number(v))}
                      contentStyle={{ borderRadius: 10, border: '1px solid #EDF1F5', fontSize: 12 }} />
                    <Bar dataKey="revenue" fill="#8B5CF6" radius={[5, 5, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card title="Platform performance" subtitle="Ringkasan performa marketplace">
              <div className="kv-list">
                <Row label="Total pengguna" value={fmtNumber(users.length)} />
                <Row label="Total listing" value={fmtNumber(products.length)} />
                <Row label="Listing aktif" value={fmtNumber(products.filter((p) => p.status === 'active').length)} />
                <Row label="Total transaksi" value={fmtNumber(orders.length)} />
                <Row label="Transaksi selesai" value={fmtNumber(totalCompleted.length)} />
                <Row label="Pendapatan (completed)" value={fmtRupiah(revenue)} />
                <Row label="Order success rate" value={`${acceptRate}%`} />
                <Row label="Rerata nilai order" value={fmtRupiah(orders.length ? Math.round(orders.reduce((s, o) => s + o.totalAmount, 0) / orders.length) : 0)} />
              </div>
            </Card>
          </div>
        </>
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
