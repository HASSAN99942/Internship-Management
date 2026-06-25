import Link from "next/link";
import { ThemeToggle } from "@/components/ui/theme-toggle";
import { ApiHealthFooter } from "./ApiHealthFooter";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center px-4 py-10">
      <div className="absolute right-4 top-4">
        <ThemeToggle />
      </div>
      <div className="w-full max-w-md">
        <Link
          href="/"
          className="mb-6 block text-center font-heading text-2xl font-bold tracking-tight"
        >
          Internship Platform
        </Link>
        {children}
        <ApiHealthFooter />
      </div>
    </div>
  );
}
