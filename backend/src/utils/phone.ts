export function normalizePhone(phone: string): string {
  if (!phone) return phone;
  
  // Remove all non-numeric characters except +
  let cleaned = phone.replace(/[^\d+]/g, '');
  
  // If it's a 10-digit number starting with 9, assume Nepal (+977)
  if (cleaned.length === 10 && cleaned.startsWith('9')) {
    return `+977${cleaned}`;
  }

  // If it starts with 977 (without +) and has 12 digits, prepend +
  if (cleaned.startsWith('977') && cleaned.length === 12) {
    return `+${cleaned}`;
  }

  // If it doesn't start with +, and is a common format, add +
  if (!cleaned.startsWith('+') && cleaned.length >= 10) {
    return `+${cleaned}`;
  }
  
  return cleaned;
}
