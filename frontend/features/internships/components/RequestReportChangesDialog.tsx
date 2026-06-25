"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
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
import { useRequestReportChanges } from "../hooks";
import { feedbackSchema, type FeedbackValues } from "../schemas";

export function RequestReportChangesDialog({ reportId }: { reportId: number }) {
  const [open, setOpen] = useState(false);
  const request = useRequestReportChanges();
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FeedbackValues>({ resolver: zodResolver(feedbackSchema) });

  const onSubmit = handleSubmit(async (values) => {
    try {
      await request.mutateAsync({ reportId, feedback: values.feedback });
      setOpen(false);
      reset();
    } catch {
      // toast handled by the mutation
    }
  });

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="sm" variant="secondary">
          Request changes
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Request changes</DialogTitle>
          <DialogDescription>
            Tell the student what to revise before resubmitting.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <Field
            label="Feedback"
            htmlFor="feedback"
            required
            error={errors.feedback?.message}
          >
            <Textarea id="feedback" rows={4} {...register("feedback")} />
          </Field>
          <DialogFooter>
            <Button type="submit" disabled={request.isPending}>
              {request.isPending ? "Sending…" : "Send feedback"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
