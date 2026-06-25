// Typed API calls for offers via the central client.

import { apiFetch, apiGet, apiPatch, apiPost } from "@/lib/api/client";
import type { Paginated } from "@/lib/api/types";
import type { Offer, OfferFilters, OfferInput } from "./types";

function buildQuery(filters: OfferFilters = {}): string {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(filters)) {
    if (value !== undefined && value !== null && value !== "") {
      params.set(key, String(value));
    }
  }
  const qs = params.toString();
  return qs ? `?${qs}` : "";
}

export function listOffers(filters: OfferFilters = {}): Promise<Paginated<Offer>> {
  return apiGet<Paginated<Offer>>(`/offers/${buildQuery(filters)}`);
}

export function listMyOffers(): Promise<Paginated<Offer>> {
  return apiGet<Paginated<Offer>>("/offers/mine/");
}

export function getOffer(id: number): Promise<Offer> {
  return apiGet<Offer>(`/offers/${id}/`);
}

export function createOffer(payload: OfferInput): Promise<Offer> {
  return apiPost<Offer>("/offers/", payload);
}

export function updateOffer(id: number, payload: Partial<OfferInput>): Promise<Offer> {
  return apiPatch<Offer>(`/offers/${id}/`, payload);
}

export function publishOffer(id: number): Promise<Offer> {
  return apiPost<Offer>(`/offers/${id}/publish/`);
}

export function closeOffer(id: number): Promise<Offer> {
  return apiPost<Offer>(`/offers/${id}/close/`);
}

export function deleteOffer(id: number): Promise<void> {
  return apiFetch<void>(`/offers/${id}/`, { method: "DELETE" });
}
