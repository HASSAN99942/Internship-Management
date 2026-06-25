import { MyApplicationsList } from "@/features/applications/components/MyApplicationsList";

export default function MyApplicationsPage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          My applications
        </h1>
        <p className="mt-1 text-muted-foreground">
          Track the status of offers you&apos;ve applied to.
        </p>
      </div>
      <MyApplicationsList />
    </div>
  );
}
