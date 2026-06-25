import type { MessageParty } from "./types";

export function partyName(p: MessageParty): string {
  return `${p.first_name} ${p.last_name}`.trim() || p.email;
}

/** Names of everyone in the thread except the current user. */
export function otherParticipants(
  participants: MessageParty[],
  meId: number | undefined,
): string {
  const others = participants.filter((p) => p.id !== meId).map(partyName);
  return others.length ? others.join(", ") : "Conversation";
}

/** Compact time for message bubbles / list rows. */
export function formatTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
