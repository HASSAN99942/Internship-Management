"use client";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth/AuthContext";
import { useAssignTeacher, useStudents } from "../hooks";
import type { StudentRow } from "../types";

function name(s: StudentRow): string {
  const full = `${s.first_name} ${s.last_name}`.trim();
  return full || s.email;
}

function StudentCard({
  student,
  action,
}: {
  student: StudentRow;
  action: React.ReactNode;
}) {
  return (
    <Card className="flex items-start justify-between gap-3 p-4">
      <div className="min-w-0">
        <p className="font-medium">{name(student)}</p>
        <p className="text-sm text-muted-foreground">
          {student.school} · {student.program} · {student.level}
        </p>
      </div>
      {action}
    </Card>
  );
}

export function MyStudentsList() {
  const { user } = useAuth();
  const { data, isLoading, isError, error } = useStudents();
  const assign = useAssignTeacher();

  if (isLoading) {
    return (
      <div className="space-y-3">
        <Skeleton className="h-20 w-full rounded-xl" />
        <Skeleton className="h-20 w-full rounded-xl" />
      </div>
    );
  }
  if (isError || !data) {
    return (
      <Card className="p-6">
        <p className="text-sm text-destructive">
          {error instanceof Error ? error.message : "Could not load students."}
        </p>
      </Card>
    );
  }

  const students = data.results;
  const mine = students.filter((s) => s.assigned_teacher?.id === user?.id);
  const available = students.filter((s) => s.assigned_teacher === null);

  return (
    <div className="space-y-8">
      <section className="space-y-3">
        <h2 className="font-heading text-lg font-semibold">
          My students ({mine.length})
        </h2>
        {mine.length === 0 ? (
          <Card className="p-6 text-center text-sm text-muted-foreground">
            You haven&apos;t added any students yet.
          </Card>
        ) : (
          mine.map((s) => (
            <StudentCard
              key={s.id}
              student={s}
              action={
                <Button
                  size="sm"
                  variant="secondary"
                  disabled={assign.isPending}
                  onClick={() =>
                    assign.mutate({ studentId: s.id, teacherId: null })
                  }
                >
                  Release
                </Button>
              }
            />
          ))
        )}
      </section>

      <section className="space-y-3">
        <h2 className="font-heading text-lg font-semibold">
          Available to claim ({available.length})
        </h2>
        {available.length === 0 ? (
          <Card className="p-6 text-center text-sm text-muted-foreground">
            No unassigned students right now.
          </Card>
        ) : (
          available.map((s) => (
            <StudentCard
              key={s.id}
              student={s}
              action={
                <Button
                  size="sm"
                  disabled={assign.isPending || !user}
                  onClick={() =>
                    user &&
                    assign.mutate({ studentId: s.id, teacherId: user.id })
                  }
                >
                  Claim
                </Button>
              }
            />
          ))
        )}
      </section>
    </div>
  );
}
