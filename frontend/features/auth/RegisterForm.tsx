"use client";

import { useRouter } from "next/navigation";
import { Controller, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { cn } from "@/lib/utils";
import { ApiError } from "@/lib/api/types";
import { useLogin, useRegister } from "./hooks";
import { dashboardPathForRole } from "@/lib/auth/AuthContext";
import { registerSchema, type RegisterValues } from "./schemas";
import type { RegisterRequest, RegisterableRole } from "./types";

const ROLES: { value: RegisterableRole; label: string }[] = [
  { value: "student", label: "Student" },
  { value: "company", label: "Company" },
  { value: "teacher", label: "Teacher" },
];

const errorRing = (on?: boolean) =>
  cn(on && "border-destructive focus-visible:ring-destructive");

// Map flat form values to the API's { ...user, profile } shape.
function toRequest(values: RegisterValues): RegisterRequest {
  const base = {
    email: values.email,
    password: values.password,
    first_name: values.first_name || "",
    last_name: values.last_name || "",
  };
  const clean = (v?: string) => (v ?? "").trim();

  if (values.role === "student") {
    return {
      ...base,
      role: "student",
      profile: {
        school: clean(values.school),
        program: clean(values.program),
        level: clean(values.level),
        phone: clean(values.phone),
      },
    };
  }
  if (values.role === "company") {
    return {
      ...base,
      role: "company",
      profile: {
        company_name: clean(values.company_name),
        sector: clean(values.sector),
        contact_phone: clean(values.contact_phone),
      },
    };
  }
  return {
    ...base,
    role: "teacher",
    profile: {
      department: clean(values.department),
      title: clean(values.title),
      phone: clean(values.phone),
    },
  };
}

export function RegisterForm() {
  const router = useRouter();
  const registerMutation = useRegister();
  const login = useLogin();
  const {
    register,
    handleSubmit,
    watch,
    control,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<RegisterValues>({
    resolver: zodResolver(registerSchema),
    defaultValues: { role: "student" },
  });

  const role = watch("role");

  const onSubmit = handleSubmit(async (values) => {
    try {
      await registerMutation.mutateAsync(toRequest(values));
      // Auto-login after successful registration, then route by role.
      const user = await login.mutateAsync({
        email: values.email,
        password: values.password,
      });
      router.replace(dashboardPathForRole(user.role));
    } catch (err) {
      const message =
        err instanceof ApiError
          ? err.message
          : "Registration failed. Please try again.";
      setError("root", { message });
    }
  });

  return (
    <form onSubmit={onSubmit} className="space-y-4" noValidate>
      <Field label="Role" htmlFor="role" required error={errors.role?.message}>
        <Controller
          control={control}
          name="role"
          render={({ field }) => (
            <Select value={field.value} onValueChange={field.onChange}>
              <SelectTrigger id="role">
                <SelectValue placeholder="Select a role" />
              </SelectTrigger>
              <SelectContent>
                {ROLES.map((r) => (
                  <SelectItem key={r.value} value={r.value}>
                    {r.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        />
      </Field>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field
          label="First name"
          htmlFor="first_name"
          error={errors.first_name?.message}
        >
          <Input id="first_name" {...register("first_name")} />
        </Field>
        <Field
          label="Last name"
          htmlFor="last_name"
          error={errors.last_name?.message}
        >
          <Input id="last_name" {...register("last_name")} />
        </Field>
      </div>

      <Field label="Email" htmlFor="email" required error={errors.email?.message}>
        <Input
          id="email"
          type="email"
          autoComplete="email"
          aria-invalid={!!errors.email}
          className={errorRing(!!errors.email)}
          {...register("email")}
        />
      </Field>

      <Field
        label="Password"
        htmlFor="password"
        required
        error={errors.password?.message}
      >
        <Input
          id="password"
          type="password"
          autoComplete="new-password"
          aria-invalid={!!errors.password}
          className={errorRing(!!errors.password)}
          {...register("password")}
        />
      </Field>

      {/* Role-specific profile fields */}
      {role === "student" && (
        <>
          <Field label="School" htmlFor="school" required error={errors.school?.message}>
            <Input
              id="school"
              aria-invalid={!!errors.school}
              className={errorRing(!!errors.school)}
              {...register("school")}
            />
          </Field>
          <Field label="Program" htmlFor="program" required error={errors.program?.message}>
            <Input
              id="program"
              aria-invalid={!!errors.program}
              className={errorRing(!!errors.program)}
              {...register("program")}
            />
          </Field>
          <Field label="Level" htmlFor="level" required error={errors.level?.message}>
            <Input
              id="level"
              placeholder="e.g. M1"
              aria-invalid={!!errors.level}
              className={errorRing(!!errors.level)}
              {...register("level")}
            />
          </Field>
          <Field label="Phone" htmlFor="phone" error={errors.phone?.message}>
            <Input id="phone" {...register("phone")} />
          </Field>
        </>
      )}

      {role === "company" && (
        <>
          <Field
            label="Company name"
            htmlFor="company_name"
            required
            error={errors.company_name?.message}
          >
            <Input
              id="company_name"
              aria-invalid={!!errors.company_name}
              className={errorRing(!!errors.company_name)}
              {...register("company_name")}
            />
          </Field>
          <Field label="Sector" htmlFor="sector" error={errors.sector?.message}>
            <Input id="sector" {...register("sector")} />
          </Field>
          <Field
            label="Contact phone"
            htmlFor="contact_phone"
            error={errors.contact_phone?.message}
          >
            <Input id="contact_phone" {...register("contact_phone")} />
          </Field>
        </>
      )}

      {role === "teacher" && (
        <>
          <Field
            label="Department"
            htmlFor="department"
            required
            error={errors.department?.message}
          >
            <Input
              id="department"
              aria-invalid={!!errors.department}
              className={errorRing(!!errors.department)}
              {...register("department")}
            />
          </Field>
          <Field label="Title" htmlFor="title" error={errors.title?.message}>
            <Input id="title" {...register("title")} />
          </Field>
          <Field label="Phone" htmlFor="phone" error={errors.phone?.message}>
            <Input id="phone" {...register("phone")} />
          </Field>
        </>
      )}

      {errors.root && (
        <p role="alert" className="text-sm text-destructive">
          {errors.root.message}
        </p>
      )}

      <Button type="submit" className="w-full" disabled={isSubmitting}>
        {isSubmitting ? "Creating account…" : "Create account"}
      </Button>
    </form>
  );
}
