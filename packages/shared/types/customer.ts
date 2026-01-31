export type Customer = {
  id: string;
  name: string;
  email: string;
  company?: string;
  createdAt: string;
  updatedAt: string;
};

export type ActivityAction =
  | "profile_viewed"
  | "contact_created"
  | "contact_updated"
  | "note_added"
  | "email_sent"
  | "meeting_scheduled";

export type Activity = {
  id: string;
  customerId: string;
  action: ActivityAction;
  description: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
};
