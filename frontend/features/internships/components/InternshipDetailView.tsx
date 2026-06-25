"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { ArrowLeft, MessageSquare } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { ProgressBar } from "@/components/ui/progress-bar";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAuth } from "@/lib/auth/AuthContext";
import { useInternshipDashboard } from "../hooks";
import { formatDate, partyName } from "../format";
import { TasksSection } from "./TasksSection";
import { ReportsSection } from "./ReportsSection";
import { EvaluationSection } from "@/features/evaluations/components/EvaluationSection";

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="text-foreground">{value}</dd>
    </div>
  );
}

export function InternshipDetailView({ internshipId }: { internshipId: number }) {
  const { user } = useAuth();
  const searchParams = useSearchParams();
  const defaultTab = searchParams.get("tab") ?? "tasks";
  const { data, isLoading, isError, error } =
    useInternshipDashboard(internshipId);

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-40 w-full rounded-xl" />
        <Skeleton className="h-64 w-full rounded-xl" />
      </div>
    );
  }
  if (isError || !data) {
    return (
      <Card className="p-6">
        <p className="text-sm text-destructive">
          {error instanceof Error ? error.message : "Internship not available."}
        </p>
        <Link
          href="/internships"
          className="mt-3 inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
        >
          <ArrowLeft className="h-4 w-4" /> Back to internships
        </Link>
      </Card>
    );
  }

  const { internship, tasks, reports, progress } = data;
  const active = internship.status === "active";

  return (
    <div className="space-y-4">
      <Link
        href="/internships"
        className="inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
      >
        <ArrowLeft className="h-4 w-4" /> Back to internships
      </Link>

      <Card className="p-6">
        <div className="flex items-start justify-between gap-3">
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            {internship.offer_title}
          </h1>
          <div className="flex shrink-0 items-center gap-2">
            <StatusBadge status={internship.status} />
            <Button asChild variant="secondary" size="sm">
              <Link href="/messages">
                <MessageSquare className="h-4 w-4" /> Messages
              </Link>
            </Button>
          </div>
        </div>

        <dl className="mt-5 grid grid-cols-2 gap-y-3 text-sm sm:grid-cols-3">
          <Detail label="Student" value={partyName(internship.student)} />
          <Detail label="Company" value={partyName(internship.company)} />
          <Detail label="Teacher" value={partyName(internship.teacher)} />
          <Detail label="Start date" value={formatDate(internship.start_date)} />
          <Detail label="End date" value={formatDate(internship.end_date)} />
        </dl>

        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <ProgressBar
            label={`Tasks validated (${progress.tasks_validated}/${progress.tasks_total})`}
            value={progress.tasks_validated_pct}
          />
          <ProgressBar
            label={`Reports validated (${progress.reports_validated}/${progress.reports_total})`}
            value={progress.reports_validated_pct}
          />
        </div>
      </Card>

      {!active && (
        <Card className="p-4 text-sm text-muted-foreground">
          Monitoring actions are available once the internship is active.
        </Card>
      )}

      <Tabs defaultValue={defaultTab} className="w-full">
        <TabsList>
          <TabsTrigger value="tasks">Tasks ({tasks.length})</TabsTrigger>
          <TabsTrigger value="reports">Reports ({reports.length})</TabsTrigger>
          <TabsTrigger value="evaluation">Evaluation</TabsTrigger>
        </TabsList>
        <TabsContent value="tasks" className="mt-4">
          <TasksSection
            internshipId={internshipId}
            tasks={tasks}
            role={user?.role}
            active={active}
          />
        </TabsContent>
        <TabsContent value="reports" className="mt-4">
          <ReportsSection
            internshipId={internshipId}
            reports={reports}
            role={user?.role}
            active={active}
          />
        </TabsContent>
        <TabsContent value="evaluation" className="mt-4">
          <EvaluationSection
            internshipId={internshipId}
            status={internship.status}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}
