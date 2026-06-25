"use client";

import Link from "next/link";
import { Briefcase, ClipboardCheck, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MetricCard } from "@/components/ui/metric-card";
import { Skeleton } from "@/components/ui/skeleton";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import { useOffers } from "@/features/offers/hooks";
import { useInternships } from "@/features/internships/hooks";
import { useStudents } from "@/features/students/hooks";
import { useAuth } from "@/lib/auth/AuthContext";

export function TeacherHome() {
  const { user } = useAuth();
  const { data, isLoading: offersLoading } = useOffers({ page: 1 });
  const { data: internshipsData, isLoading: internshipsLoading } = useInternships();
  const { data: studentsData, isLoading: studentsLoading } = useStudents();

  const offers = data?.results ?? [];
  const available = data?.count ?? 0;
  const pendingCount =
    internshipsData?.results.filter(
      (i) => i.status === "pending_academic_validation",
    ).length ?? 0;
  const myStudentCount =
    studentsData?.results.filter(
      (s) => s.assigned_teacher?.id === user?.id,
    ).length ?? 0;
  const isLoading = offersLoading || internshipsLoading || studentsLoading;

  return (
    <div className="space-y-6">
      <header>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Welcome{user?.first_name ? `, ${user.first_name}` : ""}
        </h1>
        <p className="mt-1 text-muted-foreground">
          Monitor your students&apos; internships and validate agreements.
        </p>
      </header>

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-xl" />
          ))}
        </div>
      ) : (
        <Stagger className="grid gap-4 sm:grid-cols-3">
          <StaggerItem>
            <MetricCard
              label="Published offers"
              value={available}
              icon={Briefcase}
            />
          </StaggerItem>
          <StaggerItem>
            <MetricCard
              label="Agreements to validate"
              value={pendingCount}
              icon={ClipboardCheck}
            />
          </StaggerItem>
          <StaggerItem>
            <MetricCard
              label="My students"
              value={myStudentCount}
              icon={Users}
            />
          </StaggerItem>
        </Stagger>
      )}

      <div className="flex flex-wrap gap-3">
        <Button asChild>
          <Link href="/teacher/agreements">Validate agreements</Link>
        </Button>
        <Button variant="outline" asChild>
          <Link href="/teacher/students">My students</Link>
        </Button>
        <Button variant="outline" asChild>
          <Link href="/offers">Browse offers</Link>
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-xl">Latest offers</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 3 }).map((_, i) => (
                <Skeleton key={i} className="h-10" />
              ))}
            </div>
          ) : offers.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No published offers yet.
            </p>
          ) : (
            <ul className="divide-y">
              {offers.slice(0, 5).map((o) => (
                <li
                  key={o.id}
                  className="flex items-center justify-between gap-3 py-2.5"
                >
                  <Link
                    href={`/offers/${o.id}`}
                    className="min-w-0 truncate font-medium hover:text-primary"
                  >
                    {o.title}
                  </Link>
                  <span className="shrink-0 text-sm text-muted-foreground">
                    {o.company.company_name || o.location}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
