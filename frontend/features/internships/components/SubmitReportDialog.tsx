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
import { useSubmitReport } from "../hooks";
import { reportSchema, type ReportValues } from "../schemas";

export function SubmitReportDialog({ internshipId }: { internshipId: number }) {
  const [open, setOpen] = useState(false);
  const submit = useSubmitReport(internshipId);
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ReportValues>({ resolver: zodResolver(reportSchema) });

  const onSubmit = handleSubmit(async (values) => {
    try {
      await submit.mutateAsync({
        title: values.title,
        content: values.content,
        period: values.period,
        file: values.file && values.file.length > 0 ? values.file[0] : null,
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
          <Plus className="h-4 w-4" /> Submit report
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Submit report</DialogTitle>
          <DialogDescription>
            Submit a periodic report for this internship.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <Field label="Title" htmlFor="r_title" required error={errors.title?.message}>
            <Input id="r_title" {...register("title")} />
          </Field>
          <Field
            label="Period"
            htmlFor="period"
            required
            error={errors.period?.message}
          >
            <Input id="period" placeholder="e.g. Week 1" {...register("period")} />
          </Field>
          <Field
            label="Content"
            htmlFor="content"
            required
            error={errors.content?.message}
          >
            <Textarea id="content" rows={5} {...register("content")} />
          </Field>
          <Field
            label="Attachment (optional)"
            htmlFor="r_file"
            error={errors.file?.message as string | undefined}
          >
            <Input
              id="r_file"
              type="file"
              accept=".pdf,.doc,.docx,.png,.jpg,.jpeg,.gif"
              {...register("file")}
            />
          </Field>
          <DialogFooter>
            <Button type="submit" disabled={submit.isPending}>
              {submit.isPending ? "Submitting…" : "Submit report"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
