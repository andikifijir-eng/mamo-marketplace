import { useState } from 'react';
import type { ReactNode } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { clearSession, getUser } from './api';
import {
  IconAnalytics, IconBell, IconDashboard, IconFlag, IconListings,
  IconLogout, IconReports, IconUsers,
} from './icons';
import { Pill } from './components';

export function Sidebar() {
  const loc = useLocation();
  const nav = useNavigate();
  const user = getUser();

  const items = [
    { to: '/', label: 'Dashboard', icon: <IconDashboard size={18} /> },
    { to: '/moderation', label: 'Moderation Queue', icon: <IconFlag size={18} /> },
    { to: '/listings', label: 'Listings', icon: <IconListings size={18} /> },
    { to: '/users', label: 'Users', icon: <IconUsers size={18} /> },
    { to: '/reports', label: 'Reports', icon: <IconReports size={18} /> },
    { to: '/analytics', label: 'Analytics', icon: <IconAnalytics size={18} /> },
    { to: '/verifications', label: 'Verification', icon: <IconUsers size={18} /> },
    { to: '/orders', label: 'Transactions', icon: <IconListings size={18} /> },
    { to: '/categories', label: 'Categories', icon: <IconListings size={18} /> },
  ];

  const initials = (user?.profile?.fullName || user?.email || 'A').charAt(0).toUpperCase();

  return (
    <aside className="sidebar">
      <div className="brand">
        <span className="brand-logo">M</span>
        <span className="brand-name">MAMO</span>
      </div>

      <div className="nav-label">Workspace</div>
      {items.map((it) => {
        const active = it.to === '/' ? loc.pathname === '/' : loc.pathname.startsWith(it.to);
        return (
          <Link key={it.to} to={it.to} className={`nav-item ${active ? 'active' : ''}`}>
            {it.icon}
            <span>{it.label}</span>
          </Link>
        );
      })}

      <div className="sidebar-footer">
        <span className="avatar">{initials}</span>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 12.5, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {user?.profile?.fullName || 'Admin'}
          </div>
          <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Administrator</div>
        </div>
        <button
          className="icon-btn"
          style={{ marginLeft: 'auto', width: 32, height: 32 }}
          title="Keluar"
          onClick={() => {
            clearSession();
            nav('/login');
          }}
        >
          <IconLogout size={15} />
        </button>
      </div>
    </aside>
  );
}

export function Topbar({
  breadcrumb,
  title,
  actions,
}: {
  breadcrumb: string;
  title: string;
  actions?: ReactNode;
}) {
  const user = getUser();
  const initials = (user?.profile?.fullName || user?.email || 'A').charAt(0).toUpperCase();
  return (
    <div className="topbar">
      <div>
        <div className="breadcrumb">Admin / {breadcrumb}</div>
        <h1 className="page-title">{title}</h1>
      </div>
      <div className="topbar-actions">
        {actions}
        <button className="icon-btn" title="Notifikasi">
          <IconBell size={17} />
          <span className="badge-dot" />
        </button>
        <span className="avatar">{initials}</span>
      </div>
    </div>
  );
}

export function Layout({
  breadcrumb,
  title,
  actions,
  children,
}: {
  breadcrumb: string;
  title: string;
  actions?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main">
        <Topbar breadcrumb={breadcrumb} title={title} actions={actions} />
        {children}
      </main>
    </div>
  );
}
