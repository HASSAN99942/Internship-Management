"use client";

import { MessageSquare } from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth/AuthContext";
import { useThreads } from "../hooks";
import { formatTime, otherParticipants } from "../format";

export function ThreadList({
  selectedId,
  onSelect,
}: {
  selectedId: number | null;
  onSelect: (id: number) => void;
}) {
  const { user } = useAuth();
  const { data: threads, isLoading } = useThreads();

  if (isLoading) {
    return (
      <div className="space-y-2 p-3">
        {Array.from({ length: 5 }).map((_, i) => (
          <Skeleton key={i} className="h-16 rounded-lg" />
        ))}
      </div>
    );
  }

  if (!threads || threads.length === 0) {
    return (
      <div className="flex h-full flex-col items-center justify-center gap-2 p-6 text-center text-sm text-muted-foreground">
        <MessageSquare className="h-6 w-6" />
        <p>No conversations yet.</p>
        <p>Threads appear once an internship agreement is created.</p>
      </div>
    );
  }

  return (
    <ul className="divide-y">
      {threads.map((t) => {
        const active = t.id === selectedId;
        return (
          <li key={t.id}>
            <button
              onClick={() => onSelect(t.id)}
              className={cn(
                "flex w-full flex-col gap-1 px-4 py-3 text-left transition-colors hover:bg-accent",
                active && "bg-accent",
              )}
            >
              <div className="flex items-center justify-between gap-2">
                <span className="truncate font-medium">
                  {otherParticipants(t.participants, user?.id)}
                </span>
                <span className="shrink-0 text-xs text-muted-foreground">
                  {formatTime(t.last_activity)}
                </span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="truncate text-sm text-muted-foreground">
                  {t.last_message ?? "No messages yet"}
                </span>
                {t.unread_count > 0 && (
                  <span className="flex h-5 min-w-5 shrink-0 items-center justify-center rounded-full bg-primary px-1.5 text-xs font-medium text-primary-foreground">
                    {t.unread_count}
                  </span>
                )}
              </div>
              <span className="truncate text-xs text-muted-foreground">
                {t.offer_title}
              </span>
            </button>
          </li>
        );
      })}
    </ul>
  );
}
