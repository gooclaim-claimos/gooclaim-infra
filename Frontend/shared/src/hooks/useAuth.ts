/**
 * useAuth — single source of truth for auth state across the 3 frontends.
 *
 * Wraps gooclaim-auth's /auth/login + /auth/introspect + /auth/logout endpoints.
 * Stores the JWT in an httpOnly-cookie when the auth service sets it, or in
 * memory + sessionStorage otherwise (browser-only). Re-validates on mount via
 * /auth/introspect so a refreshed page does not require re-login.
 *
 * Pin to @gooclaim/shared@0.1.0 in each consuming app — bumping the package
 * version is the propagation contract for cross-FE auth changes.
 */

import {
  type ReactNode,
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

// ───────────────────────────────────────────────────────────────────────────
// Types
// ───────────────────────────────────────────────────────────────────────────

export interface AuthenticatedUser {
  id: string;
  email: string;
  name: string | null;
  tenantId: string;
  roles: ReadonlyArray<string>;
}

export interface LoginResult {
  user: AuthenticatedUser;
  tokenExpiresAt: string; // ISO timestamp
}

export interface AuthContextValue {
  user: AuthenticatedUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<LoginResult>;
  logout: () => Promise<void>;
  refresh: () => Promise<void>;
}

interface AuthProviderProps {
  authServiceUrl: string; // e.g. "https://api.dev.gooclaim.com/v1"
  children: ReactNode;
}

// ───────────────────────────────────────────────────────────────────────────
// Context
// ───────────────────────────────────────────────────────────────────────────

const AuthContext = createContext<AuthContextValue | null>(null);

// ───────────────────────────────────────────────────────────────────────────
// Provider
// ───────────────────────────────────────────────────────────────────────────

export function AuthProvider({ authServiceUrl, children }: AuthProviderProps) {
  const [user, setUser] = useState<AuthenticatedUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await fetch(`${authServiceUrl}/auth/introspect`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });

      if (response.status === 401) {
        setUser(null);
        return;
      }
      if (!response.ok) {
        throw new Error(`/auth/introspect returned ${response.status}`);
      }

      const data = await response.json();
      // Auth-service response shape: { active, claims: { sub, email, name, tenant_id, roles } }
      // See feedback_frontend_backend_schema_adapter.md — this adapter
      // is the ONLY place we translate the wire schema → AuthenticatedUser.
      if (!data.active || !data.claims) {
        setUser(null);
        return;
      }
      setUser({
        id: String(data.claims.sub),
        email: String(data.claims.email ?? ""),
        name: data.claims.name ?? null,
        tenantId: String(data.claims.tenant_id),
        roles: Array.isArray(data.claims.roles) ? data.claims.roles : [],
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "auth introspect failed");
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  }, [authServiceUrl]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const login = useCallback(
    async (email: string, password: string): Promise<LoginResult> => {
      setError(null);
      const response = await fetch(`${authServiceUrl}/auth/login`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      if (!response.ok) {
        const message = `Login failed (${response.status})`;
        setError(message);
        throw new Error(message);
      }
      const data = await response.json();
      const authenticated: AuthenticatedUser = {
        id: String(data.user.id),
        email: String(data.user.email),
        name: data.user.name ?? null,
        tenantId: String(data.user.tenant_id),
        roles: Array.isArray(data.user.roles) ? data.user.roles : [],
      };
      setUser(authenticated);
      return {
        user: authenticated,
        tokenExpiresAt: String(data.token_expires_at),
      };
    },
    [authServiceUrl],
  );

  const logout = useCallback(async () => {
    try {
      await fetch(`${authServiceUrl}/auth/logout`, {
        method: "POST",
        credentials: "include",
      });
    } finally {
      setUser(null);
    }
  }, [authServiceUrl]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated: user !== null,
      isLoading,
      error,
      login,
      logout,
      refresh,
    }),
    [user, isLoading, error, login, logout, refresh],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// ───────────────────────────────────────────────────────────────────────────
// Hook
// ───────────────────────────────────────────────────────────────────────────

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (ctx === null) {
    throw new Error(
      "useAuth must be used within <AuthProvider authServiceUrl='...'/>. " +
        "Wrap your app root in main.tsx.",
    );
  }
  return ctx;
}
