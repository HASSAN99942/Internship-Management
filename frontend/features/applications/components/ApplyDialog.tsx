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
import { useApplyToOffer } from "../hooks";
import { applySchema, type ApplyValues } from "../schemas";

export function ApplyDialog({ offerId }: { offerId: number }) {
  const [open, setOpen] = useState(false);
  const apply = useApplyToOffer(offerId);
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ApplyValues>({ resolver: zodResolver(applySchema) });

  const onSubmit = handleSubmit(async (values) => {
    try {
      await apply.mutateAsync({
        cover_message: values.cover_message,
        cv_file:
          values.cv_file && values.cv_file.length > 0
            ? values.cv_file[0]
            : null,
      });
      setOpen(false);
      reset();
    } catch {
      // Error toast is handled by the mutation; keep the dialog open.
    }
  });

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>Apply now</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Apply to this offer</DialogTitle>
          <DialogDescription>
            Send a cover message and optionally attach your CV.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <Field
            label="Cover message"
            htmlFor="cover_message"
            required
            error={errors.cover_message?.message}
          >
            <Textarea id="cover_message" rows={5} {...register("cover_message")} />
          </Field>
          <Field
            label="CV (PDF, DOC or DOCX — optional)"
            htmlFor="cv_file"
            error={errors.cv_file?.message as string | undefined}
          >
            <Input
              id="cv_file"
              type="file"
              accept=".pdf,.doc,.docx"
              {...register("cv_file")}
            />
          </Field>
          <DialogFooter>
            <Button type="submit" disabled={apply.isPending}>
              {apply.isPending ? "Submitting…" : "Submit application"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
