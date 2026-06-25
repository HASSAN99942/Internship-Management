import {
  Briefcase,
  ClipboardCheck,
  FileText,
  FolderKanban,
  GraduationCap,
  LayoutDashboard,
  MessageSquare,
  Users,
  type LucideIcon,
} from "lucide-react";
import type { Role } from "@/features/auth/types";

export interface NavItem {
  label: string;
  href: string;
  icon: LucideIcon;
  /** false = route not built yet; rendered disabled with a "soon" hint. */
  enabled: boolean;
}

// Role-based navigation (DESIGN_SYSTEM.md table). Items whose routes don't yet
// exist are disabled until their phase ships.
export const NAV_BY_ROLE: Record<Exclude<Role, "admin">, NavItem[]> = {
  student: [
    { label: "Dashboard", href: "/student", icon: LayoutDashboard, enabled: true },
    { label: "Offers", href: "/offers", icon: Briefcase, enabled: true },
    { label: "My applications", href: "/applications", icon: FileText, enabled: true },
    { label: "My internships", href: "/internships", icon: FolderKanban, enabled: true },
    { label: "Messages", href: "/messages", icon: MessageSquare, enabled: true },
    { label: "Evaluations", href: "/evaluations", icon: ClipboardCheck, enabled: true },
  ],
  company: [
    { label: "Dashboard", href: "/company", icon: LayoutDashboard, enabled: true },
    { label: "My offers", href: "/company/offers", icon: Briefcase, enabled: true },
    { label: "Applications", href: "/company/applications", icon: FileText, enabled: true },
    { label: "Internships", href: "/internships", icon: FolderKanban, enabled: true },
    { label: "Messages", href: "/messages", icon: MessageSquare, enabled: true },
    { label: "Evaluations", href: "/evaluations", icon: ClipboardCheck, enabled: true },
  ],
  teacher: [
    { label: "Dashboard", href: "/teacher", icon: LayoutDashboard, enabled: true },
    { label: "Offers", href: "/offers", icon: Briefcase, enabled: true },
    { label: "Agreements", href: "/teacher/agreements", icon: ClipboardCheck, enabled: true },
    { label: "My students", href: "/teacher/students", icon: Users, enabled: true },
    { label: "Internships", href: "/internships", icon: FolderKanban, enabled: true },
    { label: "Messages", href: "/messages", icon: MessageSquare, enabled: true },
    { label: "Evaluations", href: "/evaluations", icon: GraduationCap, enabled: true },
  ],
};
