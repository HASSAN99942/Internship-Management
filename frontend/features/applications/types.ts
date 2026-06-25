// Types for the applications feature. Mirrors the backend serializers.

export type ApplicationStatus =
  | "pending"
  | "accepted"
  | "rejected"
  | "withdrawn";

export interface ApplicantSummary {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

export interface OfferSummary {
  id: number;
  title: string;
}

/** Read shape from ApplicationReadSerializer. */
export interface Application {
  id: number;
  offer: OfferSummary;
  student: ApplicantSummary;
  cover_message: string;
  cv_file: string | null;
  status: ApplicationStatus;
  decided_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface ApplyInput {
  cover_message: string;
  cv_file?: File | null;
}
