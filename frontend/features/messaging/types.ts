// Types for the messaging feature. Mirrors the backend serializers.

import type { Paginated } from "@/lib/api/types";

export interface MessageParty {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

export interface Message {
  id: number;
  thread: number;
  sender: MessageParty;
  body: string;
  is_read: boolean;
  created_at: string;
}

/** A conversation row (GET /threads/). */
export interface ThreadSummary {
  id: number;
  internship_id: number;
  offer_title: string;
  participants: MessageParty[];
  unread_count: number;
  last_message: string | null;
  last_activity: string;
}

/** Thread header (GET /threads/{id}/). */
export interface ThreadDetail {
  id: number;
  internship_id: number;
  offer_title: string;
  participants: MessageParty[];
}

export type MessagesPage = Paginated<Message>;
