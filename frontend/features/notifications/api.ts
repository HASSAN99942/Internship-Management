// Typed API calls for notifications via the central client.

import { apiGet, apiPost } from "@/lib/api/client";
import type { Paginated } from "@/lib/api/types";
import type { AppNotification } from "./types";

export function listNotifications(
  page = 1,
): Promise<Paginated<AppNotification>> {
  return apiGet<Paginated<AppNotification>>(`/notifications/?page=${page}`);
}

export function fetchUnreadCount(): Promise<{ unread: number }> {
  return apiGet<{ unread: number }>("/notifications/unread-count/");
}

export function markNotificationRead(id: number): Promise<AppNotification> {
  return apiPost<AppNotification>(`/notifications/${id}/read/`);
}

export function markAllNotificationsRead(): Promise<{ marked_read: number }> {
  return apiPost<{ marked_read: number }>("/notifications/read-all/");
}
