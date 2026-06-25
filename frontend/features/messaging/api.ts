// Typed API calls for messaging via the central client.

import { apiGet, apiPost } from "@/lib/api/client";
import type {
  Message,
  MessagesPage,
  ThreadDetail,
  ThreadSummary,
} from "./types";

/** GET /threads/ — the caller's threads (unread counts + last-message preview). */
export function listThreads(): Promise<ThreadSummary[]> {
  return apiGet<ThreadSummary[]>("/threads/");
}

/** GET /threads/{id}/ — participants + internship reference. */
export function getThread(id: number): Promise<ThreadDetail> {
  return apiGet<ThreadDetail>(`/threads/${id}/`);
}

/** GET /threads/{id}/messages/ — paginated, oldest first. */
export function listMessages(id: number): Promise<MessagesPage> {
  return apiGet<MessagesPage>(`/threads/${id}/messages/`);
}

/** POST /threads/{id}/messages/ — send a message. */
export function sendMessage(id: number, body: string): Promise<Message> {
  return apiPost<Message>(`/threads/${id}/messages/`, { body });
}

/** POST /threads/{id}/read/ — mark the thread read for the caller. */
export function markThreadRead(id: number): Promise<{ marked_read: number }> {
  return apiPost<{ marked_read: number }>(`/threads/${id}/read/`);
}
