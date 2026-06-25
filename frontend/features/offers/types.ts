// Types for the offers feature. Mirrors the backend serializers.

export type OfferStatus = "draft" | "published" | "closed";

export interface CompanySummary {
  id: number;
  email: string;
  company_name: string;
}

/** Read shape from OfferReadSerializer. */
export interface Offer {
  id: number;
  company: CompanySummary;
  title: string;
  description: string;
  skills: string;
  location: string;
  duration_weeks: number;
  start_date: string; // ISO date
  positions: number;
  status: OfferStatus;
  is_open: boolean;
  created_at: string;
  updated_at: string;
}

/** Write shape for create/update (OfferWriteSerializer). */
export interface OfferInput {
  title: string;
  description: string;
  skills: string;
  location: string;
  duration_weeks: number;
  start_date: string;
  positions: number;
}

/** Filters accepted by the published-offers list. */
export interface OfferFilters {
  q?: string;
  location?: string;
  duration_weeks?: number;
  company?: number;
  page?: number;
}
