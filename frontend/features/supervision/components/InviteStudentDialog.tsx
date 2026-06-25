"use client";

import { useState } from "react";
import { UserPlus } from "lucide-react";
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
import { useStudents } from "@/features/students/hooks";
import { useCreateSupervisionRequest } from "../hooks";

function studentName(s: { first_name: string; last_name: string; email: string }) {
  return `${s.first_name} ${s.last_name}`.trim() || s.email;
}

/** Teacher invites an unassigned student to supervise (student accepts). */
export function InviteStudentDialog() {
  const [open, setOpen] = useState(false);
  const [studentId, setStudentId] = useState("");
  const { data, isLoading } = useStudents();
  const create = useCreateSupervisionRequest();

  // Only students without a supervisor can be invited.
  const invitable = (data?.results ?? []).filter((s) => !s.assigned_teacher);

  const submit = async () => {
    if (!studentId) return;
    try {
      await create.mutateAsync(Number(studentId));
      setOpen(false);
      setStudentId("");
    } catch {
      // toast handled by the mutation
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="sm">
          <UserPlus className="h-4 w-4" /> Invite a student
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Invite a student</DialogTitle>
          <DialogDescription>
            Send a supervision request to a student. They&apos;ll need to accept.
          </DialogDescription>
        </DialogHeader>

        {isLoading ? (
          <Skeleton className="h-10 w-full rounded-md" />
        ) : invitable.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No unassigned students are available to invite.
          </p>
        ) : (
          <Select value={studentId} onValueChange={setStudentId}>
            <SelectTrigger>
              <SelectValue placeholder="Select a student" />
            </SelectTrigger>
            <SelectContent>
              {invitable.map((s) => (
                <SelectItem key={s.id} value={String(s.id)}>
                  {studentName(s)} · {s.program}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}

        <DialogFooter>
          <Button onClick={submit} disabled={!studentId || create.isPending}>
            {create.isPending ? "Sending…" : "Send invitation"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
