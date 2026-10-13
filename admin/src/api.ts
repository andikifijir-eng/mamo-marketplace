const TOKEN_KEY = 'mamo_admin_token';
const USER_KEY = 'mamo_admin_user';

// Vite dev pakai proxy /api -> localhost:4000
export const API_BASE = import.meta.env.VITE_API_BASE || '/api';

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function getUser(): { id: string; email: string; role: string; profile?: { fullName?: string } } | null {
  const raw = localStorage.getItem(USER_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function setSession(token: string, user: unknown) {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function clearSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export async function api<T = any>(
  path: string,
  options: { method?: string; body?: unknown; query?: Record<string, any> } = {},
): Promise<T> {
  const { method = 'GET', body, query } = options;
  let url = `${API_BASE}${path}`;
  if (query) {
    const params = new URLSearchParams();
    Object.entries(query).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') params.append(k, String(v));
    });
    const qs = params.toString();
    if (qs) url += `?${qs}`;
  }

  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(url, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401) {
    clearSession();
    if (!location.pathname.includes('/login')) location.href = '/login';
    throw new ApiError('Sesi berakhir, silakan login ulang.', 401);
  }

  let data: any = null;
  try {
    data = await res.json();
  } catch {
    data = null;
  }

  if (!res.ok) {
    const msg = data?.message || `Permintaan gagal (${res.status})`;
    throw new ApiError(msg, res.status);
  }
  return data as T;
}

export const fmtRupiah = (n: number) =>
  'Rp ' + (n || 0).toLocaleString('id-ID');

export const fmtNumber = (n: number) => (n || 0).toLocaleString('id-ID');

export const fmtDate = (iso?: string | null) => {
  if (!iso) return '-';
  return new Date(iso).toLocaleDateString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  });
};

export const fmtDateTime = (iso?: string | null) => {
  if (!iso) return '-';
  return new Date(iso).toLocaleString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
  });
};

export const timeAgo = (iso?: string | null) => {
  if (!iso) return '-';
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return 'baru saja';
  if (m < 60) return `${m} menit lalu`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} jam lalu`;
  const d = Math.floor(h / 24);
  return `${d} hari lalu`;
};
