// Types for the internships feature. Mirrors the backend serializers.

export type InternshipStatus =
  | "pending_academic_validation"
  | "active"
  | "completed"
  | "cancelled";

export type TaskStatus =
  | "open"
  | "submitted"
  | "validated"
  | "changes_requested";

export type ReportStatus = "submitted" | "validated" | "changes_requested";

export interface PartySummary {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

/** Read shape from InternshipReadSerializer. */
export interface Internship {
  id: number;
  application: number;
  offer_title: string;
  student: PartySummary;
  company: PartySummary;
  teacher: PartySummary | null;
  status: InternshipStatus;
  start_date: string;
  end_date: string;
  created_at: string;
  updated_at: string;
}

export interface Task {
  id: number;
  internship: number;
  created_by: PartySummary | null;
  title: string;
  description: string;
  due_date: string | null;
  status: TaskStatus;
  submission_note: string;
  submission_file: string | null;
  created_at: string;
  updated_at: string;
}

export interface Report {
  id: number;
  internship: number;
  student: PartySummary;
  title: string;
  content: string;
  file: string | null;
  period: string;
  status: ReportStatus;
  feedback: string;
  created_at: string;
  updated_at: string;
}

export interface Progress {
  tasks_total: number;
  tasks_validated: number;
  tasks_validated_pct: number;
  reports_total: number;
  reports_validated: number;
  reports_validated_pct: number;
}

/** Aggregate from GET /internships/{id}/. */
export interface InternshipDashboard {
  internship: Internship;
  tasks: Task[];
  reports: Report[];
  progress: Progress;
}

// --- request inputs --- //
export interface CreateTaskInput {
  title: string;
  description?: string;
  due_date?: string | null;
}

export interface SubmitTaskInput {
  submission_note?: string;
  submission_file?: File | null;
}

export interface SubmitReportInput {
  title: string;
  content: string;
  period: string;
  file?: File | null;
}
