import Link from "next/link";
import { Calendar, Clock, MapPin, Users } from "lucide-react";
import { Card } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { HoverLift } from "@/components/ui/motion";
import type { Offer } from "../types";

interface OfferCardProps {
  offer: Offer;
  href: string;
  showStatus?: boolean;
}

export function OfferCard({ offer, href, showStatus = false }: OfferCardProps) {
  return (
    <HoverLift>
      <Card className="h-full p-5 transition-shadow hover:shadow-md">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <Link
              href={href}
              className="font-heading text-base font-semibold text-foreground hover:text-primary"
            >
              {offer.title}
            </Link>
            <p className="mt-0.5 truncate text-sm text-muted-foreground">
              {offer.company.company_name || offer.company.email}
            </p>
          </div>
          {showStatus && <StatusBadge status={offer.status} />}
        </div>

        <p className="mt-3 line-clamp-2 text-sm text-muted-foreground">
          {offer.description}
        </p>

        <dl className="mt-4 flex flex-wrap gap-x-5 gap-y-1.5 text-xs text-muted-foreground">
          <span className="inline-flex items-center gap-1">
            <MapPin className="h-3.5 w-3.5" />
            {offer.location}
          </span>
          <span className="inline-flex items-center gap-1">
            <Clock className="h-3.5 w-3.5" />
            {offer.duration_weeks} weeks
          </span>
          <span className="inline-flex items-center gap-1">
            <Users className="h-3.5 w-3.5" />
            {offer.positions} position{offer.positions === 1 ? "" : "s"}
          </span>
          <span className="inline-flex items-center gap-1">
            <Calendar className="h-3.5 w-3.5" />
            {offer.start_date}
          </span>
        </dl>
      </Card>
    </HoverLift>
  );
}
