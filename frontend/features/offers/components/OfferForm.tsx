"use client";

import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Field } from "@/components/ui/field";
import { cn } from "@/lib/utils";
import { ApiError } from "@/lib/api/types";
import { useCreateOffer, useUpdateOffer } from "../hooks";
import { offerSchema, type OfferFormValues } from "../schemas";
import type { Offer } from "../types";

interface OfferFormProps {
  /** When provided, the form edits this offer; otherwise it creates one. */
  offer?: Offer;
}

const errorRing = (on?: boolean) =>
  cn(on && "border-destructive focus-visible:ring-destructive");

const todayIso = () => new Date().toISOString().split("T")[0];

export function OfferForm({ offer }: OfferFormProps) {
  const router = useRouter();
  const isEdit = Boolean(offer);
  const createOffer = useCreateOffer();
  const updateOffer = useUpdateOffer(offer?.id ?? 0);
  const mutation = isEdit ? updateOffer : createOffer;

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<OfferFormValues>({
    resolver: zodResolver(offerSchema),
    defaultValues: offer
      ? {
          title: offer.title,
          description: offer.description,
          skills: offer.skills,
          location: offer.location,
          duration_weeks: offer.duration_weeks,
          start_date: offer.start_date,
          positions: offer.positions,
        }
      : { positions: 1 },
  });

  const onSubmit = handleSubmit(async (values) => {
    try {
      await mutation.mutateAsync(values);
      toast.success(isEdit ? "Offer updated" : "Offer created");
      router.push("/company/offers");
    } catch (err) {
      setError("root", {
        message:
          err instanceof ApiError
            ? err.message
            : "Could not save the offer. Please try again.",
      });
    }
  });

  return (
    <form onSubmit={onSubmit} className="space-y-4" noValidate>
      <Field label="Title" htmlFor="title" required error={errors.title?.message}>
        <Input
          id="title"
          aria-invalid={!!errors.title}
          className={errorRing(!!errors.title)}
          {...register("title")}
        />
      </Field>

      <Field
        label="Description"
        htmlFor="description"
        required
        error={errors.description?.message}
      >
        <Textarea
          id="description"
          rows={5}
          aria-invalid={!!errors.description}
          className={errorRing(!!errors.description)}
          {...register("description")}
        />
      </Field>

      <Field
        label="Required skills"
        htmlFor="skills"
        required
        error={errors.skills?.message}
      >
        <Textarea
          id="skills"
          rows={2}
          placeholder="e.g. python, django, react"
          aria-invalid={!!errors.skills}
          className={errorRing(!!errors.skills)}
          {...register("skills")}
        />
      </Field>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field
          label="Location"
          htmlFor="location"
          required
          error={errors.location?.message}
        >
          <Input
            id="location"
            aria-invalid={!!errors.location}
            className={errorRing(!!errors.location)}
            {...register("location")}
          />
        </Field>
        <Field
          label="Start date"
          htmlFor="start_date"
          required
          error={errors.start_date?.message}
        >
          <Input
            id="start_date"
            type="date"
            min={todayIso()}
            aria-invalid={!!errors.start_date}
            className={errorRing(!!errors.start_date)}
            {...register("start_date")}
          />
        </Field>
        <Field
          label="Duration (weeks)"
          htmlFor="duration_weeks"
          required
          error={errors.duration_weeks?.message}
        >
          <Input
            id="duration_weeks"
            type="number"
            min={1}
            aria-invalid={!!errors.duration_weeks}
            className={errorRing(!!errors.duration_weeks)}
            {...register("duration_weeks")}
          />
        </Field>
        <Field
          label="Positions"
          htmlFor="positions"
          required
          error={errors.positions?.message}
        >
          <Input
            id="positions"
            type="number"
            min={1}
            aria-invalid={!!errors.positions}
            className={errorRing(!!errors.positions)}
            {...register("positions")}
          />
        </Field>
      </div>

      {errors.root && (
        <p role=”alert” className=”text-sm text-destructive”>
          {errors.root.message}
        </p>
      )}

      <div className=”sticky bottom-0 -mx-6 -mb-6 flex items-center gap-3 border-t bg-card px-6 py-4”>
        <Button type=”submit” disabled={isSubmitting}>
          {isSubmitting
            ? “Saving…”
            : isEdit
              ? “Save changes”
              : “Create offer”}
        </Button>
        <Button
          type=”button”
          variant=”secondary”
          onClick={() => router.push(“/company/offers”)}
        >
          Cancel
        </Button>
        {!isEdit && (
          <p className=”ml-2 text-xs text-muted-foreground”>
            New offers are created as draft. Publish from &ldquo;My offers&rdquo;.
          </p>
        )}
      </div>
    </form>
  );
}
