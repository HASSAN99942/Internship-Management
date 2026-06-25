"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { useMotion } from "@/lib/motion";

interface MotionDivProps {
  children: React.ReactNode;
  className?: string;
}

/** Page-level fade + small upward slide on mount. */
export function PageTransition({ children, className }: MotionDivProps) {
  const { fadeUp } = useMotion();
  return (
    <motion.div variants={fadeUp} initial="hidden" animate="show" className={className}>
      {children}
    </motion.div>
  );
}

/** Container that staggers the entrance of its <StaggerItem> children. */
export function Stagger({ children, className }: MotionDivProps) {
  const { staggerContainer } = useMotion();
  return (
    <motion.div
      variants={staggerContainer}
      initial="hidden"
      animate="show"
      className={className}
    >
      {children}
    </motion.div>
  );
}

export function StaggerItem({ children, className }: MotionDivProps) {
  const { staggerItem } = useMotion();
  return (
    <motion.div variants={staggerItem} className={className}>
      {children}
    </motion.div>
  );
}

/** Hover lift + press feedback for interactive cards. */
export function HoverLift({ children, className }: MotionDivProps) {
  const { hoverLift, tapScale } = useMotion();
  return (
    <motion.div
      whileHover={hoverLift}
      whileTap={tapScale}
      className={cn("h-full", className)}
    >
      {children}
    </motion.div>
  );
}
