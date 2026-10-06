import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import './styles.css';
import { getToken, getUser } from './api';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UsersPage from './pages/UsersPage';
import ListingsPage from './pages/ListingsPage';
import ModerationPage from './pages/ModerationPage';
import ReportsPage from './pages/ReportsPage';
import AnalyticsPage from './pages/AnalyticsPage';
import VerificationsPage from './pages/VerificationsPage';
import OrdersPage from './pages/OrdersPage';
import CategoriesPage from './pages/CategoriesPage';

/** Guard: butuh token + role admin. */
function RequireAdmin({ children }: { children: React.ReactNode }) {
  const token = getToken();
  const user = getUser();
  if (!token || user?.role !== 'admin') return <Navigate to="/login" replace />;
  return <>{children}</>;
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<RequireAdmin><DashboardPage /></RequireAdmin>} />
        <Route path="/users" element={<RequireAdmin><UsersPage /></RequireAdmin>} />
        <Route path="/listings" element={<RequireAdmin><ListingsPage /></RequireAdmin>} />
        <Route path="/moderation" element={<RequireAdmin><ModerationPage /></RequireAdmin>} />
        <Route path="/reports" element={<RequireAdmin><ReportsPage /></RequireAdmin>} />
        <Route path="/analytics" element={<RequireAdmin><AnalyticsPage /></RequireAdmin>} />
        <Route path="/verifications" element={<RequireAdmin><VerificationsPage /></RequireAdmin>} />
        <Route path="/orders" element={<RequireAdmin><OrdersPage /></RequireAdmin>} />
        <Route path="/categories" element={<RequireAdmin><CategoriesPage /></RequireAdmin>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  </React.StrictMode>,
);
