"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useMarkAllRead,
  useMarkNotificationRead,
  useNotifications,
  useUnreadCount,
} from "@/features/notifications/hooks";
import { NotificationsList } from "@/features/notifications/components/NotificationsList";
import type { AppNotification } from "@/features/notifications/types";

const PAGE_SIZE = 20;

export default function NotificationsPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const { data, isLoading, isError, error } = useNotifications(page);
  const { data: unread = 0 } = useUnreadCount();
  const markRead = useMarkNotificationRead();
  const markAll = useMarkAllRead();

  function handleOpen(n: AppNotification) {
    if (!n.is_read) markRead.mutate(n.id);
    router.push(n.payload.route);
  }

  const totalPages = data ? Math.max(1, Math.ceil(data.count / PAGE_SIZE)) : 1;

  return (
    <div className="mx-auto max-w-2xl space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Notifications
        </h1>
        {unread > 0 && (
          <Button variant="secondary" size="sm" onClick={() => markAll.mutate()}>
            Mark all as read
          </Button>
        )}
      </div>

      <Card className="p-2">
        {isLoading ? (
          <div className="space-y-2 p-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-12 w-full rounded-lg" />
            ))}
          </div>
        ) : isError ? (
          <p className="p-6 text-center text-sm text-destructive">
            {error instanceof Error ? error.message : "Could not load notifications."}
          </p>
        ) : (
          <NotificationsList
            notifications={data?.results ?? []}
            onOpen={handleOpen}
          />
        )}
      </Card>

      {data && data.count > PAGE_SIZE && (
        <div className="flex items-center justify-between text-sm">
          <Button
            variant="secondary"
            size="sm"
            disabled={!data.previous}
            onClick={() => setPage((p) => Math.max(1, p - 1))}
          >
            Previous
          </Button>
          <span className="text-muted-foreground">
            Page {page} of {totalPages}
          </span>
          <Button
            variant="secondary"
            size="sm"
            disabled={!data.next}
            onClick={() => setPage((p) => p + 1)}
          >
            Next
          </Button>
        </div>
      )}
    </div>
  );
}
