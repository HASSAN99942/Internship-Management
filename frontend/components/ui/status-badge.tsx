import { cn } from "@/lib/utils";

// Maps a domain status string to a visual variant (DESIGN_SYSTEM.md table).
type StatusVariant = "success" | "warning" | "info" | "neutral" | "destructive";

const STATUS_TO_VARIANT: Record<string, StatusVariant> = {
  // success (emerald)
  published: "success",
  active: "success",
  validated: "success",
  accepted: "success",
  // warning (amber)
  pending: "warning",
  pending_academic_validation: "warning",
  submitted: "warning",
  changes_requested: "warning",
  // neutral (slate)
  draft: "neutral",
  open: "neutral",
  withdrawn: "neutral",
  // destructive (rose)
  closed: "destructive",
  rejected: "destructive",
  cancelled: "destructive",
};

// Soft tinted background + same-family foreground; the token alpha keeps it
// legible on dark surfaces too.
const VARIANT_CLASSES: Record<StatusVariant, string> = {
  success: "bg-success/15 text-success ring-success/30",
  warning: "bg-warning/15 text-warning ring-warning/30",
  info: "bg-info/15 text-info ring-info/30",
  neutral: "bg-muted text-muted-foreground ring-border",
  destructive: "bg-destructive/15 text-destructive ring-destructive/30",
};

function humanize(status: string): string {
  const text = status.replace(/_/g, " ");
  return text.charAt(0).toUpperCase() + text.slice(1);
}

export function StatusBadge({
  status,
  className,
}: {
  status: string;
  className?: string;
}) {
  const variant = STATUS_TO_VARIANT[status] ?? "neutral";
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset",
        VARIANT_CLASSES[variant],
        className,
      )}
    >
      {humanize(status)}
    </span>
  );
}
