type CSPReport = {
  'csp-report': {
    'document-uri'?: string;
    'referrer'?: string;
    'blocked-uri'?: string;
    'violated-directive'?: string;
    'effective-directive'?: string;
    'original-policy'?: string;
    'disposition'?: string;
    'script-sample'?: string;
    'status-code'?: number;
  };
};

function redactURI(uri?: string): string | undefined {
  if (!uri) return undefined;
  try {
    const url = new URL(uri);
    return `${url.protocol}//${url.hostname}${url.pathname}`;
  } catch {
    return '[redacted-uri]';
  }
}

function redactSample(sample?: string): string | undefined {
  if (!sample) return undefined;
  if (sample.length > 100) {
    return `${sample.substring(0, 50)}...[truncated]`;
  }
  return sample;
}

export function redactCSPReport(report: CSPReport): CSPReport {
  return {
    'csp-report': {
      'document-uri': redactURI(report['csp-report']['document-uri']),
      'referrer': redactURI(report['csp-report']['referrer']),
      'blocked-uri': redactURI(report['csp-report']['blocked-uri']),
      'violated-directive': report['csp-report']['violated-directive'],
      'effective-directive': report['csp-report']['effective-directive'],
      'original-policy': report['csp-report']['original-policy'],
      'disposition': report['csp-report']['disposition'],
      'script-sample': redactSample(report['csp-report']['script-sample']),
      'status-code': report['csp-report']['status-code'],
    },
  };
}

export type { CSPReport };
