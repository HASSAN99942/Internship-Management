"use client";

import { cn } from "@/lib/utils";
import { relativeTime } from "../format";
import type { AppNotification } from "../types";

/** A single notification row, reused by the bell dropdown and the full page. */
export function NotificationItem({
  notification,
  onOpen,
}: {
  notification: AppNotification;
  onOpen: (n: AppNotification) => void;
}) {
  return (
    <button
      type="button"
      onClick={() => onOpen(notification)}
      className={cn(
        "flex w-full items-start gap-3 rounded-lg px-3 py-2 text-left text-sm transition-colors hover:bg-accent",
        !notification.is_read && "bg-accent/40",
      )}
    >
      <span
        className={cn(
          "mt-1.5 h-2 w-2 shrink-0 rounded-full",
          notification.is_read ? "bg-transparent" : "bg-primary",
        )}
        aria-hidden
      />
      <span className="min-w-0 flex-1">
        <span className="block truncate-none text-foreground">
          {notification.payload.message}
        </span>
        <span className="mt-0.5 block text-xs text-muted-foreground">
          {relativeTime(notification.created_at)}
        </span>
      </span>
    </button>
  );
}
