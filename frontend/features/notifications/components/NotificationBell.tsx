"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  useMarkAllRead,
  useMarkNotificationRead,
  useNotifications,
  useUnreadCount,
} from "../hooks";
import type { AppNotification } from "../types";
import { NotificationsList } from "./NotificationsList";

export function NotificationBell() {
  const [open, setOpen] = useState(false);
  const router = useRouter();
  const { data: unread = 0 } = useUnreadCount();
  const { data: page } = useNotifications(1);
  const markRead = useMarkNotificationRead();
  const markAll = useMarkAllRead();

  const recent = (page?.results ?? []).slice(0, 8);

  function handleOpen(n: AppNotification) {
    if (!n.is_read) markRead.mutate(n.id);
    setOpen(false);
    router.push(n.payload.route);
  }

  return (
    <DropdownMenu open={open} onOpenChange={setOpen}>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="relative"
          aria-label={unread > 0 ? `Notifications (${unread} unread)` : "Notifications"}
        >
          <Bell className="h-5 w-5" />
          {unread > 0 && (
            <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-primary px-1 text-[10px] font-semibold leading-none text-primary-foreground ring-2 ring-background">
              {unread > 9 ? "9+" : unread}
            </span>
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-80 p-0">
        <div className="flex items-center justify-between px-3 py-2">
          <span className="text-sm font-semibold">Notifications</span>
          {unread > 0 && (
            <button
              type="button"
              onClick={() => markAll.mutate()}
              className="text-xs font-medium text-primary hover:underline"
            >
              Mark all as read
            </button>
          )}
        </div>
        <Separator />
        <div className="max-h-80 overflow-y-auto p-1">
          <NotificationsList
            notifications={recent}
            onOpen={handleOpen}
            emptyHint="No notifications yet."
          />
        </div>
        <Separator />
        <Link
          href="/notifications"
          onClick={() => setOpen(false)}
          className="block px-3 py-2 text-center text-sm font-medium text-primary hover:underline"
        >
          View all notifications
        </Link>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
