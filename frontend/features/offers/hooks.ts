"use client";

// React Query hooks for offers. Mutations invalidate the lists/detail they affect.

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import {
  closeOffer,
  createOffer,
  deleteOffer,
  getOffer,
  listMyOffers,
  listOffers,
  publishOffer,
  updateOffer,
} from "./api";
import type { OfferFilters, OfferInput } from "./types";

export const offerKeys = {
  all: ["offers"] as const,
  list: (filters: OfferFilters) => ["offers", "list", filters] as const,
  mine: ["offers", "mine"] as const,
  detail: (id: number) => ["offers", "detail", id] as const,
};

export function useOffers(filters: OfferFilters = {}) {
  return useQuery({
    queryKey: offerKeys.list(filters),
    queryFn: () => listOffers(filters),
  });
}

export function useMyOffers() {
  return useQuery({
    queryKey: offerKeys.mine,
    queryFn: listMyOffers,
  });
}

export function useOffer(id: number) {
  return useQuery({
    queryKey: offerKeys.detail(id),
    queryFn: () => getOffer(id),
    enabled: Number.isFinite(id),
  });
}

// Invalidate every offer query (lists + mine + details) after a write.
function useInvalidateOffers() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: offerKeys.all });
}

export function useCreateOffer() {
  const invalidate = useInvalidateOffers();
  return useMutation({
    mutationFn: (payload: OfferInput) => createOffer(payload),
    onSuccess: invalidate,
  });
}

export function useUpdateOffer(id: number) {
  const invalidate = useInvalidateOffers();
  return useMutation({
    mutationFn: (payload: Partial<OfferInput>) => updateOffer(id, payload),
    onSuccess: invalidate,
  });
}

export function usePublishOffer() {
  const invalidate = useInvalidateOffers();
  return useMutation({
    mutationFn: (id: number) => publishOffer(id),
    onSuccess: invalidate,
  });
}

export function useCloseOffer() {
  const invalidate = useInvalidateOffers();
  return useMutation({
    mutationFn: (id: number) => closeOffer(id),
    onSuccess: invalidate,
  });
}

export function useDeleteOffer() {
  const invalidate = useInvalidateOffers();
  return useMutation({
    mutationFn: (id: number) => deleteOffer(id),
    onSuccess: invalidate,
  });
}
