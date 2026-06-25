"use client";

import { useEffect, useRef, useState } from "react";
import { ArrowLeft, Check, CheckCheck, Send } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth/AuthContext";
import {
  useMarkThreadRead,
  useMessages,
  useSendMessage,
  useThread,
} from "../hooks";
import { formatTime, otherParticipants, partyName } from "../format";

export function ConversationPane({
  threadId,
  onBack,
}: {
  threadId: number;
  onBack?: () => void;
}) {
  const { user } = useAuth();
  const { data: thread } = useThread(threadId);
  const { data: page, isLoading } = useMessages(threadId);
  const send = useSendMessage(threadId);
  const markRead = useMarkThreadRead();
  const [body, setBody] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);

  const messages = page?.results ?? [];
  const count = messages.length;

  // Mark the thread read when opened and whenever new messages arrive.
  useEffect(() => {
    markRead.mutate(threadId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [threadId, count]);

  // Auto-scroll to the latest message.
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [count]);

  const submit = async () => {
    const text = body.trim();
    if (!text) return;
    try {
      await send.mutateAsync(text);
      setBody("");
    } catch {
      // toast handled by the mutation
    }
  };

  return (
    <div className="flex h-full flex-col">
      <header className="flex items-center gap-2 border-b px-4 py-3">
        {onBack && (
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={onBack}
            aria-label="Back to conversations"
          >
            <ArrowLeft className="h-4 w-4" />
          </Button>
        )}
        <div className="min-w-0">
          <p className="truncate font-medium">
            {thread ? otherParticipants(thread.participants, user?.id) : "…"}
          </p>
          {thread && (
            <p className="truncate text-xs text-muted-foreground">
              {thread.offer_title}
            </p>
          )}
        </div>
      </header>

      <div className="flex-1 overflow-y-auto p-4">
        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 4 }).map((_, i) => (
              <Skeleton key={i} className="h-12 w-2/3 rounded-lg" />
            ))}
          </div>
        ) : count === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            No messages yet. Say hello.
          </p>
        ) : (
          messages.map((m, i) => {
            const isOwn = m.sender.id === user?.id;
            const prev = messages[i - 1];
            const firstOfRun = !prev || prev.sender.id !== m.sender.id;
            return (
              <div
                key={m.id}
                className={cn(
                  "flex flex-col",
                  isOwn ? "items-end" : "items-start",
                  firstOfRun ? "mt-3 first:mt-0" : "mt-0.5",
                )}
              >
                {/* Group thread: show the sender's name once per run, others only */}
                {!isOwn && firstOfRun && (
                  <span className="mb-1 px-1 text-xs font-medium text-muted-foreground">
                    {partyName(m.sender)}
                  </span>
                )}
                <div
                  className={cn(
                    "max-w-[75%] px-3.5 py-2 text-sm shadow-sm",
                    isOwn
                      ? "rounded-[14px] rounded-br-sm bg-primary text-primary-foreground"
                      : "rounded-[14px] rounded-bl-sm bg-muted text-foreground",
                  )}
                >
                  <p className="whitespace-pre-wrap break-words">{m.body}</p>
                </div>
                <span className="mt-1 flex items-center gap-1 px-1 text-[11px] text-muted-foreground">
                  {formatTime(m.created_at)}
                  {isOwn &&
                    (m.is_read ? (
                      <CheckCheck
                        className="h-3.5 w-3.5 text-primary"
                        aria-label="Read"
                      />
                    ) : (
                      <Check className="h-3.5 w-3.5" aria-label="Sent" />
                    ))}
                </span>
              </div>
            );
          })
        )}
        <div ref={bottomRef} />
      </div>

      <div className="flex items-end gap-2 border-t p-3">
        <Textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              void submit();
            }
          }}
          rows={1}
          placeholder="Write a message…  (Enter to send)"
          className="max-h-32 min-h-10 resize-none"
        />
        <Button
          size="icon"
          onClick={submit}
          disabled={!body.trim() || send.isPending}
          aria-label="Send message"
        >
          <Send className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
