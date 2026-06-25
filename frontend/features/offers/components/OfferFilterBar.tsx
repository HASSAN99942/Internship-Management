"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { OfferFilters } from "../types";

interface OfferFilterBarProps {
  initial: OfferFilters;
  onApply: (filters: OfferFilters) => void;
}

/** Keyword / location / duration filter bar for the published offers list. */
export function OfferFilterBar({ initial, onApply }: OfferFilterBarProps) {
  const [q, setQ] = useState(initial.q ?? "");
  const [location, setLocation] = useState(initial.location ?? "");
  const [duration, setDuration] = useState(
    initial.duration_weeks ? String(initial.duration_weeks) : "",
  );

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const durationNum = Number.parseInt(duration, 10);
    onApply({
      q: q.trim() || undefined,
      location: location.trim() || undefined,
      duration_weeks: Number.isFinite(durationNum) ? durationNum : undefined,
    });
  };

  const reset = () => {
    setQ("");
    setLocation("");
    setDuration("");
    onApply({});
  };

  return (
    <form
      onSubmit={submit}
      className="flex flex-wrap items-end gap-3 rounded-xl border bg-card p-4"
    >
      <div className="min-w-[12rem] flex-1 space-y-1.5">
        <Label htmlFor="filter-q">Keyword</Label>
        <Input
          id="filter-q"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="title, skills…"
        />
      </div>
      <div className="min-w-[10rem] flex-1 space-y-1.5">
        <Label htmlFor="filter-location">Location</Label>
        <Input
          id="filter-location"
          value={location}
          onChange={(e) => setLocation(e.target.value)}
          placeholder="e.g. Casablanca"
        />
      </div>
      <div className="w-32 space-y-1.5">
        <Label htmlFor="filter-duration">Duration (wks)</Label>
        <Input
          id="filter-duration"
          type="number"
          min={1}
          value={duration}
          onChange={(e) => setDuration(e.target.value)}
        />
      </div>
      <div className="flex gap-2">
        <Button type="submit">Filter</Button>
        <Button type="button" variant="secondary" onClick={reset}>
          Reset
        </Button>
      </div>
    </form>
  );
}
