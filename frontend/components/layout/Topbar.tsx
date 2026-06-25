"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { Menu, MessageSquare, Search } from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ThemeToggle } from "@/components/ui/theme-toggle";
import { useAuth } from "@/lib/auth/AuthContext";
import { useLogout } from "@/features/auth/hooks";
import { useThreads } from "@/features/messaging/hooks";
import { NotificationBell } from "@/features/notifications/components/NotificationBell";

function displayName(firstName: string, lastName: string, email: string): string {
  const full = `${firstName} ${lastName}`.trim();
  return full || email;
}

function initials(firstName: string, lastName: string, email: string): string {
  const a = firstName.trim()[0] ?? "";
  const b = lastName.trim()[0] ?? "";
  const combined = `${a}${b}`.trim();
  return (combined || email[0] || "?").toUpperCase();
}

export function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const router = useRouter();
  const { user } = useAuth();
  const logout = useLogout();
  const { data: threads } = useThreads();
  const unreadTotal = (threads ?? []).reduce((n, t) => n + t.unread_count, 0);

  const first = user?.first_name ?? "";
  const last = user?.last_name ?? "";
  const email = user?.email ?? "";

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b bg-background/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-background/80">
      <Button
        variant="ghost"
        size="icon"
        className="lg:hidden"
        onClick={onMenuClick}
        aria-label="Open navigation menu"
      >
        <Menu className="h-5 w-5" />
      </Button>

      <div className="relative hidden w-full max-w-sm sm:block">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input placeholder="Search…" className="pl-9" aria-label="Search" />
      </div>

      <div className="ml-auto flex items-center gap-1">
        <ThemeToggle />

        <Button
          asChild
          variant="ghost"
          size="icon"
          className="relative"
          aria-label={
            unreadTotal > 0 ? `Messages (${unreadTotal} unread)` : "Messages"
          }
        >
          <Link href="/messages">
            <MessageSquare className="h-5 w-5" />
            {unreadTotal > 0 && (
              <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-primary ring-2 ring-background" />
            )}
          </Link>
        </Button>

        <NotificationBell />

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="rounded-full" aria-label="Account menu">
              <Avatar className="h-8 w-8">
                <AvatarFallback className="bg-primary/10 text-primary">
                  {initials(first, last, email)}
                </AvatarFallback>
              </Avatar>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>
              <div className="flex flex-col">
                <span className="truncate text-sm font-medium">
                  {displayName(first, last, email)}
                </span>
                <span className="truncate text-xs font-normal capitalize text-muted-foreground">
                  {user?.role}
                </span>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem disabled>Profile</DropdownMenuItem>
            <DropdownMenuItem
              onClick={() =>
                logout.mutate(undefined, {
                  onSuccess: () => router.replace("/login"),
                })
              }
            >
              Log out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
