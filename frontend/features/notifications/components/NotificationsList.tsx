"use client";

import { Bell } from "lucide-react";
import type { AppNotification } from "../types";
import { NotificationItem } from "./NotificationItem";

/** Presentational list of notifications with an empty state. */
export function NotificationsList({
  notifications,
  onOpen,
  emptyHint = "You have no notifications yet.",
}: {
  notifications: AppNotification[];
  onOpen: (n: AppNotification) => void;
  emptyHint?: string;
}) {
  if (notifications.length === 0) {
    return (
      <div className="flex flex-col items-center gap-2 px-3 py-10 text-center text-sm text-muted-foreground">
        <Bell className="h-6 w-6" />
        {emptyHint}
      </div>
    );
  }
  return (
    <ul className="space-y-1">
      {notifications.map((n) => (
        <li key={n.id}>
          <NotificationItem notification={n} onOpen={onOpen} />
        </li>
      ))}
    </ul>
  );
}
