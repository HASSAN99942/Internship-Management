"use client";

import { useState } from "react";
import { MessageSquare } from "lucide-react";
import { cn } from "@/lib/utils";
import { ThreadList } from "@/features/messaging/components/ThreadList";
import { ConversationPane } from "@/features/messaging/components/ConversationPane";

export default function MessagesPage() {
  const [selectedId, setSelectedId] = useState<number | null>(null);

  return (
    <div className="space-y-4">
      <h1 className="font-heading text-3xl font-bold tracking-tight">Messages</h1>

      <div className="grid h-[calc(100vh-12rem)] overflow-hidden rounded-xl border bg-card md:grid-cols-[20rem_1fr]">
        {/* Conversation list — hidden on mobile once a thread is open. */}
        <div
          className={cn(
            "overflow-y-auto border-r md:block",
            selectedId !== null && "hidden",
          )}
        >
          <ThreadList selectedId={selectedId} onSelect={setSelectedId} />
        </div>

        {/* Conversation pane — replaces the list on mobile when selected. */}
        <div className={cn("min-h-0", selectedId === null && "hidden md:block")}>
          {selectedId !== null ? (
            <ConversationPane
              threadId={selectedId}
              onBack={() => setSelectedId(null)}
            />
          ) : (
            <div className="flex h-full flex-col items-center justify-center gap-2 text-center text-sm text-muted-foreground">
              <MessageSquare className="h-7 w-7" />
              <p>Select a conversation to start messaging.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
