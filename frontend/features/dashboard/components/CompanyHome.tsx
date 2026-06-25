"use client";

import Link from "next/link";
import { Briefcase, CheckCircle2, FileEdit, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MetricCard } from "@/components/ui/metric-card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import { useMyOffers } from "@/features/offers/hooks";
import { useAuth } from "@/lib/auth/AuthContext";

export function CompanyHome() {
  const { user } = useAuth();
  const { data, isLoading } = useMyOffers();
  const offers = data?.results ?? [];
  const total = data?.count ?? 0;
  const published = offers.filter((o) => o.status === "published").length;
  const drafts = offers.filter((o) => o.status === "draft").length;

  return (
    <div className="space-y-6">
      <header>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Welcome{user?.first_name ? `, ${user.first_name}` : ""}
        </h1>
        <p className="mt-1 text-muted-foreground">
          An overview of your internship offers.
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
            <MetricCard label="Total offers" value={total} icon={Briefcase} />
          </StaggerItem>
          <StaggerItem>
            <MetricCard label="Published" value={published} icon={CheckCircle2} />
          </StaggerItem>
          <StaggerItem>
            <MetricCard label="Drafts" value={drafts} icon={FileEdit} />
          </StaggerItem>
        </Stagger>
      )}

      <div className="flex flex-wrap gap-3">
        <Button asChild>
          <Link href="/company/offers/new">
            <Plus className="h-4 w-4" />
            New offer
          </Link>
        </Button>
        <Button variant="secondary" asChild>
          <Link href="/company/offers">Manage offers</Link>
        </Button>
        <Button variant="ghost" asChild>
          <Link href="/offers">Browse all</Link>
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-xl">Recent offers</CardTitle>
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
              No offers yet. Create your first one.
            </p>
          ) : (
            <ul className="divide-y">
              {offers.slice(0, 5).map((o) => (
                <li
                  key={o.id}
                  className="flex items-center justify-between py-2.5"
                >
                  <Link
                    href={`/offers/${o.id}`}
                    className="font-medium hover:text-primary"
                  >
                    {o.title}
                  </Link>
                  <StatusBadge status={o.status} />
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
