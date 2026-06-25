// Types for the student-supervision feature (teacher "My students").

export interface AssignedTeacher {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

/** A student row from GET /api/v1/students/ (id = student user id). */
export interface StudentRow {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  school: string;
  program: string;
  level: string;
  assigned_teacher: AssignedTeacher | null;
}
