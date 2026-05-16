/**
 * DataroomProvider — propagates the 6 Dataroom correlation IDs to every
 * outbound fetch made by the consuming React app.
 *
 * The Dataroom convention (see backend memory `reference_dataroom_convention.md`)
 * uses 6 IDs (tenant_id, dataroom_id, correlation_id, request_id, session_id,
 * interaction_id) carried as `X-*` headers. Every gooclaim service expects them
 * on every request. This provider stamps them automatically.
 *
 * Usage:
 *   <DataroomProvider initialContext={...}>
 *     <App />
 *   </DataroomProvider>
 *
 *   // inside any component:
 *   const { context, fetchWithDataroom } = useDataroom();
 *   const res = await fetchWithDataroom("/v1/claims", { method: "GET" });
 */

import {
  type ReactNode,
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from "react";

// ───────────────────────────────────────────────────────────────────────────
// Types
// ───────────────────────────────────────────────────────────────────────────

export interface DataroomContext {
  tenantId: string;
  dataroomId: string | null;
  correlationId: string;
  requestId: string | null;
  sessionId: string | null;
  interactionId: string | null;
}

export interface DataroomHeaders {
  "X-Tenant-ID": string;
  "X-Dataroom-ID": string;
  "X-Correlation-ID": string;
  "X-Request-ID": string;
  "X-Session-ID": string;
  "X-Interaction-ID": string;
}

interface DataroomContextValue {
  context: DataroomContext;
  setContext: (partial: Partial<DataroomContext>) => void;
  headers: () => DataroomHeaders;
  fetchWithDataroom: (
    input: RequestInfo | URL,
    init?: RequestInit,
  ) => Promise<Response>;
}

interface DataroomProviderProps {
  initialContext: DataroomContext;
  children: ReactNode;
}

// ───────────────────────────────────────────────────────────────────────────
// Helpers
// ───────────────────────────────────────────────────────────────────────────

function buildHeaders(ctx: DataroomContext): DataroomHeaders {
  return {
    "X-Tenant-ID": ctx.tenantId,
    "X-Dataroom-ID": ctx.dataroomId ?? "",
    "X-Correlation-ID": ctx.correlationId,
    "X-Request-ID": ctx.requestId ?? "",
    "X-Session-ID": ctx.sessionId ?? "",
    "X-Interaction-ID": ctx.interactionId ?? "",
  };
}

// ───────────────────────────────────────────────────────────────────────────
// Context
// ───────────────────────────────────────────────────────────────────────────

const DataroomCtx = createContext<DataroomContextValue | null>(null);

export function DataroomProvider({
  initialContext,
  children,
}: DataroomProviderProps) {
  const [ctx, setCtx] = useState<DataroomContext>(initialContext);

  const updateContext = useCallback((partial: Partial<DataroomContext>) => {
    setCtx((prev) => ({ ...prev, ...partial }));
  }, []);

  const headers = useCallback(() => buildHeaders(ctx), [ctx]);

  const fetchWithDataroom = useCallback(
    async (input: RequestInfo | URL, init: RequestInit = {}) => {
      const merged: HeadersInit = {
        ...buildHeaders(ctx),
        ...(init.headers ?? {}),
      };
      return fetch(input, { ...init, headers: merged, credentials: "include" });
    },
    [ctx],
  );

  const value = useMemo<DataroomContextValue>(
    () => ({
      context: ctx,
      setContext: updateContext,
      headers,
      fetchWithDataroom,
    }),
    [ctx, updateContext, headers, fetchWithDataroom],
  );

  return <DataroomCtx.Provider value={value}>{children}</DataroomCtx.Provider>;
}

export function useDataroom(): DataroomContextValue {
  const ctx = useContext(DataroomCtx);
  if (ctx === null) {
    throw new Error(
      "useDataroom must be used within <DataroomProvider initialContext={...}>. " +
        "Wrap your app root after AuthProvider.",
    );
  }
  return ctx;
}
