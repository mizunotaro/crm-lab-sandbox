import { cspReportHandler } from '../app/api/security/csp-report/route.js';

type TestResult = {
  name: string;
  passed: boolean;
  error?: string;
};

async function runTests(): Promise<TestResult[]> {
  const results: TestResult[] = [];

  results.push(await testNonPostMethod());
  results.push(await testInvalidContentType());
  results.push(await testInvalidBody());
  results.push(await testValidCSPReport());
  results.push(await testCSPReportWithURIs());
  results.push(await testCSPReportWithLongScriptSample());

  return results;
}

async function testNonPostMethod(): Promise<TestResult> {
  try {
    const response = await cspReportHandler({
      method: 'GET',
      headers: {},
    });

    if (response.status !== 405) {
      return {
        name: 'Non-POST method returns 405',
        passed: false,
        error: `Expected status 405, got ${response.status}`,
      };
    }

    if (response.headers?.['Allow'] !== 'POST') {
      return {
        name: 'Non-POST method returns 405',
        passed: false,
        error: 'Expected Allow header with POST',
      };
    }

    return { name: 'Non-POST method returns 405', passed: true };
  } catch (error) {
    return {
      name: 'Non-POST method returns 405',
      passed: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function testInvalidContentType(): Promise<TestResult> {
  try {
    const response = await cspReportHandler({
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: { 'csp-report': {} },
    });

    if (response.status !== 400) {
      return {
        name: 'Invalid content type returns 400',
        passed: false,
        error: `Expected status 400, got ${response.status}`,
      };
    }

    return { name: 'Invalid content type returns 400', passed: true };
  } catch (error) {
    return {
      name: 'Invalid content type returns 400',
      passed: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function testInvalidBody(): Promise<TestResult> {
  try {
    const response = await cspReportHandler({
      method: 'POST',
      headers: { 'content-type': 'application/csp-report' },
      body: {},
    });

    if (response.status !== 400) {
      return {
        name: 'Invalid body returns 400',
        passed: false,
        error: `Expected status 400, got ${response.status}`,
      };
    }

    return { name: 'Invalid body returns 400', passed: true };
  } catch (error) {
    return {
      name: 'Invalid body returns 400',
      passed: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function testValidCSPReport(): Promise<TestResult> {
  try {
    const response = await cspReportHandler({
      method: 'POST',
      headers: { 'content-type': 'application/csp-report' },
      body: {
        'csp-report': {
          'violated-directive': 'script-src-elem',
          'effective-directive': 'script-src-elem',
        },
      },
    });

    if (response.status !== 204) {
      return {
        name: 'Valid CSP report returns 204',
        passed: false,
        error: `Expected status 204, got ${response.status}`,
      };
    }

    return { name: 'Valid CSP report returns 204', passed: true };
  } catch (error) {
    return {
      name: 'Valid CSP report returns 204',
      passed: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function testCSPReportWithURIs(): Promise<TestResult> {
  try {
    const response = await cspReportHandler({
      method: 'POST',
      headers: { 'content-type': 'application/csp-report' },
      body: {
        'csp-report': {
          'document-uri': 'https://example.com/page?token=secret123',
          'referrer': 'https://example.com/home',
          'blocked-uri': 'https://evil.com/script.js?data=sensitive',
          'violated-directive': 'script-src',
        },
      },
    });

    if (response.status !== 204) {
      return {
        name: 'CSP report with URIs returns 204',
        passed: false,
        error: `Expected status 204, got ${response.status}`,
      };
    }

    return { name: 'CSP report with URIs returns 204', passed: true };
  } catch (error) {
    return {
      name: 'CSP report with URIs returns 204',
      passed: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function testCSPReportWithLongScriptSample(): Promise<TestResult> {
  try {
    const longSample = 'a'.repeat(200);
    const response = await cspReportHandler({
      method: 'POST',
      headers: { 'content-type': 'application/csp-report' },
      body: {
        'csp-report': {
          'script-sample': longSample,
          'violated-directive': 'script-src',
        },
      },
    });

    if (response.status !== 204) {
      return {
        name: 'CSP report with long script sample returns 204',
        passed: false,
        error: `Expected status 204, got ${response.status}`,
      };
    }

    return { name: 'CSP report with long script sample returns 204', passed: true };
  } catch (error) {
    return {
      name: 'CSP report with long script sample returns 204',
      passed: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

function printResults(results: TestResult[]): void {
  const passed = results.filter((r) => r.passed).length;
  const failed = results.length - passed;

  console.log('\n=== CSP Report Endpoint Test Results ===\n');

  for (const result of results) {
    const status = result.passed ? '✓' : '✗';
    console.log(`${status} ${result.name}`);
    if (result.error) {
      console.log(`  Error: ${result.error}`);
    }
  }

  console.log(`\nTotal: ${results.length} tests`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  console.log('\n=====================================\n');
}

async function main(): Promise<boolean> {
  const results = await runTests();
  printResults(results);

  return results.every((r) => r.passed);
}

main().then((passed) => {
  console.log(`\nAll tests ${passed ? 'passed' : 'failed'}\n`);
});
