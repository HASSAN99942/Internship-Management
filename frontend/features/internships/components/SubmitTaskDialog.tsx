"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Field } from "@/components/ui/field";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { useSubmitTask } from "../hooks";
import { submitTaskSchema, type SubmitTaskValues } from "../schemas";
import type { Task } from "../types";

export function SubmitTaskDialog({ task }: { task: Task }) {
  const [open, setOpen] = useState(false);
  const submit = useSubmitTask();
  const isResubmit = task.status === "changes_requested";
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<SubmitTaskValues>({ resolver: zodResolver(submitTaskSchema) });

  const onSubmit = handleSubmit(async (values) => {
    try {
      await submit.mutateAsync({
        taskId: task.id,
        submission_note: values.submission_note,
        submission_file:
          values.submission_file && values.submission_file.length > 0
            ? values.submission_file[0]
            : null,
      });
      setOpen(false);
      reset();
    } catch {
      // toast handled by the mutation
    }
  });

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="sm" variant={isResubmit ? "default" : "secondary"}>
          {isResubmit ? "Resubmit" : "Submit"}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isResubmit ? "Resubmit task" : "Submit task"}</DialogTitle>
          <DialogDescription>{task.title}</DialogDescription>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <Field
            label="Note"
            htmlFor="submission_note"
            error={errors.submission_note?.message}
          >
            <Textarea id="submission_note" rows={4} {...register("submission_note")} />
          </Field>
          <Field
            label="Attachment (optional)"
            htmlFor="submission_file"
            error={errors.submission_file?.message as string | undefined}
          >
            <Input
              id="submission_file"
              type="file"
              accept=".pdf,.doc,.docx,.png,.jpg,.jpeg,.gif"
              {...register("submission_file")}
            />
          </Field>
          <DialogFooter>
            <Button type="submit" disabled={submit.isPending}>
              {submit.isPending ? "Submitting…" : "Submit"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
