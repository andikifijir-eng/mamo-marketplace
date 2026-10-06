import { useCallback, useEffect, useState } from 'react';
import { api, fmtNumber } from '../api';
import { Card, EmptyState, ErrorState, Modal, Pill, Spinner } from '../components';
import { Layout } from '../Layout';
import { IconListings, IconPlus } from '../icons';

export default function CategoriesPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [modal, setModal] = useState<{ mode: 'create' | 'edit'; data: any } | null>(null);
  const [form, setForm] = useState({ name: '', icon: 'category', status: 'active' });
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api<any>('/admin/categories');
      setRows(res.categories);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  function openCreate() {
    setForm({ name: '', icon: 'category', status: 'active' });
    setModal({ mode: 'create', data: null });
  }

  function openEdit(c: any) {
    setForm({ name: c.name, icon: c.icon ?? 'category', status: c.status ?? 'active' });
    setModal({ mode: 'edit', data: c });
  }

  async function save() {
    if (!form.name.trim()) return alert('Nama kategori wajib diisi');
    setBusy(true);
    try {
      if (modal?.mode === 'create') {
        await api('/admin/categories', { method: 'POST', body: form });
      } else {
        await api(`/admin/categories/${modal?.data.id}`, { method: 'PUT', body: form });
      }
      setModal(null);
      await load();
    } catch (e: any) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(c: any) {
    if (!confirm(`Hapus kategori "${c.name}"?`)) return;
    try {
      const res = await api<any>(`/admin/categories/${c.id}`, { method: 'DELETE' });
      await load();
      if (res.softDeleted) {
        alert('Kategori dipakai produk, jadi dinonaktifkan (soft delete).');
      }
    } catch (e: any) {
      alert(e.message);
    }
  }

  return (
    <Layout
      breadcrumb="Categories"
      title="Categories"
      actions={
        <button className="btn btn-primary" onClick={openCreate}>
          <IconPlus size={15} /> Kategori Baru
        </button>
      }
    >
      <Card title="Daftar Kategori" subtitle="Kelola kategori produk marketplace">
        {loading && <Spinner />}
        {!loading && error && <ErrorState message={error} onRetry={load} />}
        {!loading && !error && rows.length === 0 && (
          <EmptyState message="Belum ada kategori" icon={<IconListings />} />
        )}
        {!loading && !error && rows.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Nama</th>
                  <th>Icon</th>
                  <th>Status</th>
                  <th>Produk</th>
                  <th>Dibuat</th>
                  <th>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((c) => (
                  <tr key={c.id}>
                    <td className="cell-strong">{c.name}</td>
                    <td className="cell-sub">{c.icon ?? '-'}</td>
                    <td>
                      <Pill kind={c.status === 'active' ? 'green' : 'gray'}>
                        {c.status === 'active' ? 'Aktif' : 'Nonaktif'}
                      </Pill>
                    </td>
                    <td>{fmtNumber(c._count?.products ?? 0)}</td>
                    <td className="cell-sub">
                      {c.createdAt ? new Date(c.createdAt).toLocaleDateString('id-ID') : '-'}
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button className="btn btn-sm" onClick={() => openEdit(c)}>Edit</button>
                        <button className="btn btn-sm btn-danger" onClick={() => remove(c)}>Hapus</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {modal && (
        <Modal
          title={modal.mode === 'create' ? 'Kategori Baru' : 'Edit Kategori'}
          onClose={() => setModal(null)}
          actions={
            <>
              <button className="btn" onClick={() => setModal(null)} disabled={busy}>Batal</button>
              <button className="btn btn-primary" onClick={save} disabled={busy}>
                {busy ? 'Menyimpan...' : 'Simpan'}
              </button>
            </>
          }
        >
          <div className="form-group">
            <label>Nama kategori</label>
            <input className="input" value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder="Contoh: Elektronik" />
          </div>
          <div className="form-row">
            <div className="form-group">
              <label>Icon (nama icon)</label>
              <input className="input" value={form.icon}
                onChange={(e) => setForm({ ...form, icon: e.target.value })} />
            </div>
            <div className="form-group">
              <label>Status</label>
              <select className="select" value={form.status}
                onChange={(e) => setForm({ ...form, status: e.target.value })}>
                <option value="active">Aktif</option>
                <option value="inactive">Nonaktif</option>
              </select>
            </div>
          </div>
        </Modal>
      )}
    </Layout>
  );
}
