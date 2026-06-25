"use client";

import { cn } from "@/lib/utils";

interface RatingInputProps {
  value: number;
  onChange?: (value: number) => void;
  max?: number;
  readOnly?: boolean;
  label?: string;
}

/**
 * Numeric score input 1–max. Interactive: clickable number chips.
 * Read-only: renders "score / max" as text. Max defaults to 10.
 */
export function RatingInput({
  value,
  onChange,
  max = 10,
  readOnly = false,
  label,
}: RatingInputProps) {
  if (readOnly) {
    return (
      <span
        className="tabular-nums font-semibold text-primary"
        aria-label={label ? `${label}: ${value} out of ${max}` : undefined}
      >
        {value}{" "}
        <span className="text-xs font-normal text-muted-foreground">
          / {max}
        </span>
      </span>
    );
  }

  const numbers = Array.from({ length: max }, (_, i) => i + 1);

  return (
    <div
      className="flex flex-wrap gap-1"
      role="radiogroup"
      aria-label={label}
    >
      {numbers.map((n) => (
        <button
          key={n}
          type="button"
          role="radio"
          aria-checked={n === value}
          aria-label={`${n} out of ${max}`}
          onClick={() => onChange?.(n)}
          className={cn(
            "flex h-7 w-7 items-center justify-center rounded text-xs font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
            n === value
              ? "bg-primary text-primary-foreground"
              : "border border-input bg-background text-muted-foreground hover:bg-accent hover:text-accent-foreground",
          )}
        >
          {n}
        </button>
      ))}
    </div>
  );
}
