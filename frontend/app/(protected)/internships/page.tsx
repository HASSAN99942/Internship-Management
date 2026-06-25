import { InternshipsList } from "@/features/internships/components/InternshipsList";

export default function InternshipsPage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Internships
        </h1>
        <p className="mt-1 text-muted-foreground">
          Internship agreements you are a party to.
        </p>
      </div>
      <InternshipsList />
    </div>
  );
}
