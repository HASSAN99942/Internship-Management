"use client";

import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

// Admins are managed via the Django admin site (CLAUDE.md), not a frontend app.
export default function AdminNotice() {
  const base =
    process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000";
  return (
    <div className="space-y-4">
      <h1 className="font-heading text-3xl font-bold tracking-tight">
        Administrator
      </h1>
      <Card>
        <CardContent className="p-6">
          <p className="text-muted-foreground">
            Administration is handled in the Django admin site rather than this
            app.
          </p>
          <Button asChild className="mt-4">
            <a href={`${base}/admin/`}>Open Django admin</a>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
