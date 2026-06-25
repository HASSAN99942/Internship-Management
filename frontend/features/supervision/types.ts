// Types for the supervision-request flow. Mirrors the backend serializers.
// (Teacher options live in features/auth; student rows in features/students.)

export type SupervisionStatus =
  | "pending"
  | "accepted"
  | "rejected"
  | "cancelled";

export type Initiator = "student" | "teacher";

export interface SupervisionParty {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

export interface SupervisionRequest {
  id: number;
  student: SupervisionParty;
  teacher: SupervisionParty;
  initiated_by: Initiator;
  status: SupervisionStatus;
  decided_at: string | null;
  created_at: string;
  updated_at: string;
}
