// Types for the auth feature. Mirrors the backend accounts serializers.

export type Role = "student" | "company" | "teacher" | "admin";

/** Roles a visitor may self-register as (admin is created by an admin only). */
export type RegisterableRole = Exclude<Role, "admin">;

/** A teacher embedded as a student's supervisor in profile reads. */
export interface SupervisorBrief {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

/** A selectable teacher from GET /api/v1/teachers/. */
export interface TeacherOption {
  id: number;
  full_name: string;
  email: string;
  department: string;
}

export interface StudentProfile {
  school: string;
  program: string;
  level: string;
  phone: string;
  cv_file: string | null;
  assigned_teacher: SupervisorBrief | null;
}

export interface CompanyProfile {
  company_name: string;
  sector: string;
  website: string;
  address: string;
  description: string;
  contact_phone: string;
}

export interface TeacherProfile {
  department: string;
  title: string;
  phone: string;
}

export type Profile =
  | StudentProfile
  | CompanyProfile
  | TeacherProfile
  | null;

/** Response shape of GET /api/v1/me/ and POST /api/v1/auth/register/. */
export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  role: Role;
  is_active: boolean;
  date_joined: string;
  profile: Profile;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface TokenPair {
  access: string;
  refresh: string;
  role: Role;
}

/** Profile payload — string fields, plus assigned_teacher (id) for students. */
export type ProfilePayload = Record<string, string | number | null>;

export interface RegisterRequest {
  email: string;
  password: string;
  first_name?: string;
  last_name?: string;
  role: RegisterableRole;
  profile: ProfilePayload;
}

export interface MeUpdateRequest {
  first_name?: string;
  last_name?: string;
  profile?: ProfilePayload;
}
