"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { useTeachers } from "@/features/auth/hooks";
import { useCreateSupervisionRequest } from "../hooks";

/** Student picks a teacher and sends a supervision request (teacher accepts). */
export function RequestSupervisorDialog() {
  const [open, setOpen] = useState(false);
  const [teacherId, setTeacherId] = useState("");
  const { data: teachers, isLoading } = useTeachers(open);
  const create = useCreateSupervisionRequest();

  const submit = async () => {
    if (!teacherId) return;
    try {
      await create.mutateAsync(Number(teacherId));
      setOpen(false);
      setTeacherId("");
    } catch {
      // toast handled by the mutation
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>Request a supervisor</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Request a supervisor</DialogTitle>
          <DialogDescription>
            Choose a teacher to supervise your internship. They&apos;ll need to
            accept the request.
          </DialogDescription>
        </DialogHeader>

        {isLoading ? (
          <Skeleton className="h-10 w-full rounded-md" />
        ) : (teachers ?? []).length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No teachers are available yet.
          </p>
        ) : (
          <Select value={teacherId} onValueChange={setTeacherId}>
            <SelectTrigger>
              <SelectValue placeholder="Select a teacher" />
            </SelectTrigger>
            <SelectContent>
              {(teachers ?? []).map((t) => (
                <SelectItem key={t.id} value={String(t.id)}>
                  {t.full_name || t.email}
                  {t.department ? ` · ${t.department}` : ""}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}

        <DialogFooter>
          <Button onClick={submit} disabled={!teacherId || create.isPending}>
            {create.isPending ? "Sending…" : "Send request"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
