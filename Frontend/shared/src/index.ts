/**
 * @gooclaim/shared — barrel exports
 *
 * Consumers (gooclaim-console, gooclaim-copilot, gooclaim-portal) import
 * from this entrypoint. Sub-path imports (./hooks/useAuth etc.) are also
 * exposed in package.json `exports` for tree-shaking.
 */

export { AuthProvider, useAuth } from "./hooks/useAuth";
export type {
  AuthContextValue,
  AuthenticatedUser,
  LoginResult,
} from "./hooks/useAuth";

export { DataroomProvider, useDataroom } from "./components/DataroomProvider";
export type {
  DataroomContext as DataroomContextType,
  DataroomHeaders,
} from "./components/DataroomProvider";

export { tailwindPreset } from "./lib/tailwind-preset";
