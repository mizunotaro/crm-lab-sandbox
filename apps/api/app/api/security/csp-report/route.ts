import { redactCSPReport, type CSPReport } from '../../../../lib/logging/redact.js';

export interface Request {
  method: string;
  headers: Record<string, string>;
  body?: unknown;
}

export interface Response {
  status: number;
  headers?: Record<string, string>;
  body?: unknown;
}

export type CSPReportHandler = (req: Request) => Promise<Response>;

export const cspReportHandler: CSPReportHandler = async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return {
      status: 405,
      headers: { 'Allow': 'POST' },
    };
  }

  try {
    const contentType = req.headers['content-type'] || '';
    if (!contentType.includes('application/csp-report')) {
      return {
        status: 400,
      };
    }

    const body = req.body as CSPReport;
    if (!body || !body['csp-report']) {
      return {
        status: 400,
      };
    }

    const redactedReport = redactCSPReport(body);

    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      type: 'csp-violation',
      report: redactedReport,
    }));

    return {
      status: 204,
      headers: { 'Content-Type': 'text/plain' },
    };
  } catch (error) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      type: 'csp-error',
      error: error instanceof Error ? error.message : 'Unknown error',
    }));

    return {
      status: 204,
      headers: { 'Content-Type': 'text/plain' },
    };
  }
};

export { redactCSPReport, type CSPReport } from '../../../../lib/logging/redact.js';
