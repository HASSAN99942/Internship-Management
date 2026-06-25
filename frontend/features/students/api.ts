// Typed API calls for student supervision via the central client.

import { apiGet, apiPatch } from "@/lib/api/client";
import type { Paginated } from "@/lib/api/types";
import type { StudentRow } from "./types";

/** GET /students/ — supervision list (teacher: own + unassigned; admin: all). */
export function listStudents(): Promise<Paginated<StudentRow>> {
  return apiGet<Paginated<StudentRow>>("/students/");
}

/** PATCH /students/{id}/ — set (teacherId) or clear (null) the assigned teacher. */
export function assignTeacher(
  studentId: number,
  teacherId: number | null,
): Promise<StudentRow> {
  return apiPatch<StudentRow>(`/students/${studentId}/`, {
    assigned_teacher: teacherId,
  });
}
