import { MyStudentsList } from "@/features/students/components/MyStudentsList";
import { InviteStudentDialog } from "@/features/supervision/components/InviteStudentDialog";
import { SupervisionRequestsPanel } from "@/features/supervision/components/SupervisionRequestsPanel";

export default function MyStudentsPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="font-heading text-3xl font-bold tracking-tight">
            My students
          </h1>
          <p className="mt-1 text-muted-foreground">
            Respond to supervision requests, invite students, or claim/release
            ones directly.
          </p>
        </div>
        <InviteStudentDialog />
      </div>
      <SupervisionRequestsPanel />
      <MyStudentsList />
    </div>
  );
}
