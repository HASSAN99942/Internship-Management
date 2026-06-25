// Client-side validation for the apply form. Mirrors the backend serializer.

import { z } from "zod";

const ALLOWED_EXTENSIONS = ["pdf", "doc", "docx"];
const MAX_CV_SIZE = 5 * 1024 * 1024; // 5 MB

export const applySchema = z.object({
  cover_message: z
    .string()
    .min(1, "A cover message is required")
    .max(5000, "Cover message is too long"),
  // RHF gives a FileList for <input type="file">; CV is optional.
  cv_file: z
    .custom<FileList>()
    .optional()
    .refine(
      (files) => !files || files.length === 0 || files[0].size <= MAX_CV_SIZE,
      "CV must be 5 MB or smaller",
    )
    .refine((files) => {
      if (!files || files.length === 0) return true;
      const name = files[0].name.toLowerCase();
      const ext = name.includes(".") ? name.split(".").pop()! : "";
      return ALLOWED_EXTENSIONS.includes(ext);
    }, "CV must be a PDF, DOC or DOCX file"),
});

export type ApplyValues = z.infer<typeof applySchema>;
