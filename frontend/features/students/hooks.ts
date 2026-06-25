"use client";

// React Query hooks for student supervision.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ApiError } from "@/lib/api/types";
import { assignTeacher, listStudents } from "./api";

export const studentKeys = {
  all: ["students"] as const,
  list: ["students", "list"] as const,
};

export function useStudents() {
  return useQuery({ queryKey: studentKeys.list, queryFn: listStudents });
}

/**
 * Claim or release a student. Pass a teacherId to claim (the current teacher's
 * id) or null to release.
 */
export function useAssignTeacher() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      studentId,
      teacherId,
    }: {
      studentId: number;
      teacherId: number | null;
    }) => assignTeacher(studentId, teacherId),
    onSuccess: (_data, { teacherId }) => {
      queryClient.invalidateQueries({ queryKey: studentKeys.all });
      toast.success(teacherId ? "Student added to your list" : "Student released");
    },
    onError: (err) =>
      toast.error(
        err instanceof ApiError ? err.message : "Could not update the student.",
      ),
  });
}
