// Client-side form validation (zod). Mirrors the backend's required fields so
// users get fast feedback; the server remains the source of truth.

import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().min(1, "Email is required").email("Enter a valid email"),
  password: z.string().min(1, "Password is required"),
});

export type LoginValues = z.infer<typeof loginSchema>;

// A single flat object (rather than a discriminated union) so react-hook-form
// field paths stay simple. Role-specific required fields are enforced in
// superRefine, matching the backend write serializers.
export const registerSchema = z
  .object({
    email: z.string().min(1, "Email is required").email("Enter a valid email"),
    password: z
      .string()
      .min(8, "Password must be at least 8 characters")
      .max(128, "Password is too long"),
    first_name: z.string().max(150).optional(),
    last_name: z.string().max(150).optional(),
    role: z.enum(["student", "company", "teacher"]),
    // Profile fields — optional at the type level, conditionally required below.
    school: z.string().optional(),
    program: z.string().optional(),
    level: z.string().optional(),
    company_name: z.string().optional(),
    sector: z.string().optional(),
    department: z.string().optional(),
    title: z.string().optional(),
    phone: z.string().optional(),
    contact_phone: z.string().optional(),
  })
  .superRefine((val, ctx) => {
    const requireField = (field: keyof typeof val, message: string) => {
      const value = val[field];
      if (typeof value !== "string" || value.trim() === "") {
        ctx.addIssue({ code: z.ZodIssueCode.custom, path: [field], message });
      }
    };

    if (val.role === "student") {
      requireField("school", "School is required");
      requireField("program", "Program is required");
      requireField("level", "Level is required");
    } else if (val.role === "company") {
      requireField("company_name", "Company name is required");
    } else if (val.role === "teacher") {
      requireField("department", "Department is required");
    }
  });

export type RegisterValues = z.infer<typeof registerSchema>;
