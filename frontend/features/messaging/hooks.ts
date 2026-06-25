"use client";

// React Query hooks for messaging. The open thread and the thread list poll
// lightly for near-real-time updates (no WebSockets).

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ApiError } from "@/lib/api/types";
import {
  getThread,
  listMessages,
  listThreads,
  markThreadRead,
  sendMessage,
} from "./api";

export const messagingKeys = {
  all: ["messaging"] as const,
  threads: ["messaging", "threads"] as const,
  thread: (id: number) => ["messaging", "thread", id] as const,
  messages: (id: number) => ["messaging", "messages", id] as const,
};

const POLL_MS = 15_000;

export function useThreads() {
  return useQuery({
    queryKey: messagingKeys.threads,
    queryFn: listThreads,
    refetchInterval: POLL_MS,
  });
}

export function useThread(id: number | null) {
  return useQuery({
    queryKey: messagingKeys.thread(id ?? 0),
    queryFn: () => getThread(id as number),
    enabled: id != null,
  });
}

export function useMessages(id: number | null) {
  return useQuery({
    queryKey: messagingKeys.messages(id ?? 0),
    queryFn: () => listMessages(id as number),
    enabled: id != null,
    refetchInterval: id != null ? POLL_MS : false,
  });
}

export function useSendMessage(threadId: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: string) => sendMessage(threadId, body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: messagingKeys.messages(threadId) });
      queryClient.invalidateQueries({ queryKey: messagingKeys.threads });
    },
    onError: (err) =>
      toast.error(
        err instanceof ApiError ? err.message : "Could not send the message.",
      ),
  });
}

export function useMarkThreadRead() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (threadId: number) => markThreadRead(threadId),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: messagingKeys.threads }),
  });
}
