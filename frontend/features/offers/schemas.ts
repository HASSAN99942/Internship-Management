// Form validation for offer create/edit (mirrors OfferWriteSerializer).

import { z } from "zod";

export const offerSchema = z.object({
  title: z.string().min(1, "Title is required").max(255),
  description: z.string().min(1, "Description is required"),
  skills: z.string().min(1, "Required skills are required"),
  location: z.string().min(1, "Location is required").max(255),
  duration_weeks: z.coerce
    .number({ invalid_type_error: "Enter a number" })
    .int("Must be a whole number")
    .min(1, "Must be at least 1 week"),
  start_date: z
    .string()
    .min(1, "Start date is required")
    .refine((v) => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      return new Date(v) >= today;
    }, "Start date cannot be in the past"),
  positions: z.coerce
    .number({ invalid_type_error: "Enter a number" })
    .int("Must be a whole number")
    .min(1, "Must be at least 1"),
});

export type OfferFormValues = z.infer<typeof offerSchema>;
