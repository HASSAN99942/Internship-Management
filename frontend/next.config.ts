import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // Pin the workspace root to this app so Next.js does not infer it from an
  // unrelated lockfile elsewhere on the machine.
  outputFileTracingRoot: path.join(__dirname),
};

export default nextConfig;
