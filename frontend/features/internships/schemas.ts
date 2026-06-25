// Client-side validation for task/report forms. Mirrors the backend.

import { z } from "zod";

const ALLOWED_EXTENSIONS = ["pdf", "doc", "docx", "png", "jpg", "jpeg", "gif"];
const MAX_SIZE = 5 * 1024 * 1024; // 5 MB

// RHF gives a FileList for <input type="file">; the attachment is optional.
const optionalFile = z
  .custom<FileList>()
  .optional()
  .refine(
    (files) => !files || files.length === 0 || files[0].size <= MAX_SIZE,
    "File must be 5 MB or smaller",
  )
  .refine((files) => {
    if (!files || files.length === 0) return true;
    const name = files[0].name.toLowerCase();
    const ext = name.includes(".") ? name.split(".").pop()! : "";
    return ALLOWED_EXTENSIONS.includes(ext);
  }, "File type not allowed (pdf, doc, docx, or image)");

export const taskSchema = z.object({
  title: z.string().min(1, "Title is required").max(255),
  description: z.string().max(5000).optional(),
  due_date: z
    .string()
    .optional()
    .refine((v) => {
      if (!v) return true;
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      return new Date(v) >= today;
    }, "Due date cannot be in the past"),
});
export type TaskValues = z.infer<typeof taskSchema>;

export const submitTaskSchema = z.object({
  submission_note: z.string().max(5000).optional(),
  submission_file: optionalFile,
});
export type SubmitTaskValues = z.infer<typeof submitTaskSchema>;

export const reportSchema = z.object({
  title: z.string().min(1, "Title is required").max(255),
  period: z.string().min(1, "Period is required").max(100),
  content: z.string().min(1, "Content is required"),
  file: optionalFile,
});
export type ReportValues = z.infer<typeof reportSchema>;

export const feedbackSchema = z.object({
  feedback: z.string().min(1, "Feedback is required").max(5000),
});
export type FeedbackValues = z.infer<typeof feedbackSchema>;
