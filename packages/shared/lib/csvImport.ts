import { isEnabled } from './featureFlags';

export interface Contact {
  id: string;
  name: string;
  email: string;
  phone?: string;
}

export interface CsvImportResult {
  success: boolean;
  imported: number;
  errors: string[];
}

export async function importContactsFromCsv(csvContent: string): Promise<CsvImportResult> {
  if (!isEnabled('CSV_IMPORT')) {
    return {
      success: false,
      imported: 0,
      errors: ['CSV import feature is disabled'],
    };
  }

  const lines = csvContent.split('\n').filter((line) => line.trim());
  if (lines.length < 2) {
    return {
      success: false,
      imported: 0,
      errors: ['CSV file must have at least a header and one data row'],
    };
  }

  const headers = lines[0].split(',').map((h) => h.trim().toLowerCase());
  const contacts: Contact[] = [];
  const errors: string[] = [];

  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(',').map((v) => v.trim());
    const contact: Partial<Contact> = { id: crypto.randomUUID() };

    headers.forEach((header, index) => {
      const value = values[index] || '';
      if (header === 'name') contact.name = value;
      if (header === 'email') contact.email = value;
      if (header === 'phone') contact.phone = value;
    });

    if (!contact.name || !contact.email) {
      errors.push(`Row ${i}: Missing required fields (name, email)`);
    } else {
      contacts.push(contact as Contact);
    }
  }

  return {
    success: errors.length === 0,
    imported: contacts.length,
    errors,
  };
}
