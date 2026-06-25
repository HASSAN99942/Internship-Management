"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Plus } from "lucide-react";
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
import { useCreateTask } from "../hooks";
import { taskSchema, type TaskValues } from "../schemas";

export function NewTaskDialog({ internshipId }: { internshipId: number }) {
  const [open, setOpen] = useState(false);
  const createTask = useCreateTask(internshipId);
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<TaskValues>({ resolver: zodResolver(taskSchema) });

  const onSubmit = handleSubmit(async (values) => {
    try {
      await createTask.mutateAsync({
        title: values.title,
        description: values.description,
        due_date: values.due_date || null,
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
        <Button size="sm">
          <Plus className="h-4 w-4" /> New task
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New task</DialogTitle>
          <DialogDescription>
            Assign a task for the intern to complete.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <Field label="Title" htmlFor="title" required error={errors.title?.message}>
            <Input id="title" {...register("title")} />
          </Field>
          <Field
            label="Description"
            htmlFor="description"
            error={errors.description?.message}
          >
            <Textarea id="description" rows={4} {...register("description")} />
          </Field>
          <Field label="Due date" htmlFor="due_date" error={errors.due_date?.message}>
            <Input
              id="due_date"
              type="date"
              min={new Date().toISOString().split("T")[0]}
              {...register("due_date")}
            />
          </Field>
          <DialogFooter>
            <Button type="submit" disabled={createTask.isPending}>
              {createTask.isPending ? "Creating…" : "Create task"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
