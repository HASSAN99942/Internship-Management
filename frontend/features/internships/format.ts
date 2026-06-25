import type { PartySummary } from "./types";

/** Display name for an internship party, falling back to email then a dash. */
export function partyName(party: PartySummary | null): string {
  if (!party) return "—";
  const full = `${party.first_name} ${party.last_name}`.trim();
  return full || party.email;
}

/** Format an ISO date (YYYY-MM-DD or datetime) for display; "—" if empty. */
export function formatDate(value: string | null | undefined): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
