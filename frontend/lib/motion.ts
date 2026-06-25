"use client";

// Framer Motion variants + a reduced-motion-aware hook.
// Durations 150-250ms, ease-out. Two weights: state feedback and entrance.
// When the user prefers reduced motion, transforms are dropped (opacity only).

import { useReducedMotion, type Variants } from "framer-motion";

export const fadeUp: Variants = {
  hidden: { opacity: 0, y: 10 },
  show: { opacity: 1, y: 0, transition: { duration: 0.22, ease: "easeOut" } },
};

export const staggerContainer: Variants = {
  hidden: {},
  show: { transition: { staggerChildren: 0.05 } },
};

export const staggerItem: Variants = {
  hidden: { opacity: 0, y: 12 },
  show: { opacity: 1, y: 0, transition: { duration: 0.22, ease: "easeOut" } },
};

// Opacity-only fallbacks used when prefers-reduced-motion is set.
const fadeOnly: Variants = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { duration: 0.15 } },
};

const noStagger: Variants = { hidden: {}, show: {} };

/** Returns motion variants, downgraded to opacity-only under reduced motion. */
export function useMotion() {
  const reduce = useReducedMotion();
  return {
    reduce: !!reduce,
    fadeUp: reduce ? fadeOnly : fadeUp,
    staggerContainer: reduce ? noStagger : staggerContainer,
    staggerItem: reduce ? fadeOnly : staggerItem,
    hoverLift: reduce
      ? {}
      : { y: -3, transition: { duration: 0.18, ease: "easeOut" as const } },
    tapScale: reduce ? {} : { scale: 0.97 },
  };
}
