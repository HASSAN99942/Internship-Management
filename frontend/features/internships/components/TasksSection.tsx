"use client";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import type { Role } from "@/features/auth/types";
import { useRequestTaskChanges, useValidateTask } from "../hooks";
import { formatDate } from "../format";
import { NewTaskDialog } from "./NewTaskDialog";
import { SubmitTaskDialog } from "./SubmitTaskDialog";
import type { Task } from "../types";

export function TasksSection({
  internshipId,
  tasks,
  role,
  active,
}: {
  internshipId: number;
  tasks: Task[];
  role: Role | undefined;
  active: boolean;
}) {
  const isStudent = role === "student";
  const isSupervisor =
    role === "company" || role === "teacher" || role === "admin";
  const validate = useValidateTask();
  const requestChanges = useRequestTaskChanges();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-heading text-lg font-semibold">Tasks</h2>
        {isSupervisor && active && <NewTaskDialog internshipId={internshipId} />}
      </div>

      {tasks.length === 0 ? (
        <Card className="p-6 text-center text-sm text-muted-foreground">
          No tasks yet.
        </Card>
      ) : (
        <ul className="space-y-3">
          {tasks.map((task) => (
            <Card key={task.id} className="p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="font-medium">{task.title}</p>
                  {task.description && (
                    <p className="mt-1 text-sm text-muted-foreground">
                      {task.description}
                    </p>
                  )}
                  {task.due_date && (
                    <p className="mt-1 text-xs text-muted-foreground">
                      Due {formatDate(task.due_date)}
                    </p>
                  )}
                  {task.submission_note && (
                    <p className="mt-2 rounded-md bg-muted p-2 text-sm">
                      {task.submission_note}
                    </p>
                  )}
                  {task.submission_file && (
                    <a
                      href={task.submission_file}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-1 inline-block text-sm font-medium text-primary hover:underline"
                    >
                      View attachment
                    </a>
                  )}
                </div>
                <StatusBadge status={task.status} />
              </div>

              {active && (
                <div className="mt-3 flex flex-wrap gap-2">
                  {isStudent &&
                    (task.status === "open" ||
                      task.status === "changes_requested") && (
                      <SubmitTaskDialog task={task} />
                    )}
                  {isSupervisor && task.status === "submitted" && (
                    <>
                      <ConfirmDialog
                        trigger={<Button size="sm">Validate</Button>}
                        title="Validate task?"
                        confirmLabel="Validate"
                        pending={validate.isPending}
                        onConfirm={() => validate.mutateAsync(task.id)}
                      />
                      <ConfirmDialog
                        trigger={
                          <Button size="sm" variant="secondary">
                            Request changes
                          </Button>
                        }
                        title="Request changes?"
                        description="The task returns to the student to revise and resubmit."
                        confirmLabel="Request changes"
                        pending={requestChanges.isPending}
                        onConfirm={() => requestChanges.mutateAsync(task.id)}
                      />
                    </>
                  )}
                </div>
              )}
            </Card>
          ))}
        </ul>
      )}
    </div>
  );
}
