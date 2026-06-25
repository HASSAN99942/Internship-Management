// Shared types for API responses. As features are built, response shapes for
// each endpoint are declared here (see CLAUDE.md conventions).

/** Response shape of `GET /api/health/`. */
export interface HealthResponse {
  status: string;
}

/** DRF paginated list envelope (PageNumberPagination). */
export interface Paginated<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

/** Normalised error thrown by the API client on a failed request. */
export class ApiError extends Error {
  readonly status: number;
  readonly data: unknown;

  constructor(message: string, status: number, data: unknown = null) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.data = data;
  }
}
