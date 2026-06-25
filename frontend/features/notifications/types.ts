// Types for the notifications feature. Mirrors the backend serializer.

export type NotificationType =
  | "application_received"
  | "application_accepted"
  | "application_rejected"
  | "agreement_to_validate"
  | "internship_activated"
  | "task_assigned"
  | "task_submitted"
  | "task_validated"
  | "task_changes_requested"
  | "report_submitted"
  | "report_validated"
  | "report_changes_requested"
  | "new_message"
  | "evaluation_submitted";

export interface NotificationPayload {
  message: string;
  route: string;
  [key: string]: unknown;
}

// Named AppNotification to avoid clashing with the browser's global Notification.
export interface AppNotification {
  id: number;
  type: NotificationType;
  payload: NotificationPayload;
  is_read: boolean;
  created_at: string;
}
