# Daily Report Operations

This document describes how to use the dashboard issue template for daily report aggregation.

## Overview

The dashboard issue template provides a consistent format for tracking daily operations and aggregating reports from automated workflows.

## Creating a Dashboard Issue

### Manual Creation

1. Go to **Issues** > **New Issue**
2. Select the **Dashboard Issue** template
3. Review and update the template content as needed
4. Submit the issue

### Automated Creation

The dashboard issue can be created as part of the initial setup or on-demand.

## Dashboard Structure

The dashboard issue includes the following sections:

### Latest Daily Reports

A table tracking daily reports with:
- **Date**: Report date (YYYY-MM-DD format)
- **Report Link**: Link to the daily report issue or comment
- **Status**: ✅ (green), ⚠️ (warning), or ❌ (error)

### Current Sprint Status

Information about the current sprint:
- **Sprint Goal**: Current sprint objectives
- **Progress**: Sprint progress update

### Key Metrics

High-level metrics:
- Open Issues count
- Open PRs count
- Active Blockers count

### Active Blockers

List of any blocking issues or concerns.

### Recent Wins

Celebration of recent accomplishments.

### Notes

Additional context or information.

## Daily Workflow Integration

The `ai-daily.yml` workflow can comment on the dashboard issue with:

1. Link to the daily report issue
2. Summary of key activities
3. Status indicators

## Maintenance

### Weekly Updates

- Update sprint goal and progress
- Review and clean up old reports
- Update metrics

### Monthly Updates

- Archive old dashboard issues
- Review and update template as needed
- Assess metrics and reporting needs

## Related Files

- `.github/ISSUE_TEMPLATE/dashboard.md`: The dashboard issue template
- `.github/workflows/ai-daily.yml`: Daily report workflow

## Example Daily Report Comment

```
**Date:** 2026-01-31
**Report:** #123

**Summary:**
- Merged 3 PRs
- 2 new issues opened
- 0 critical issues

**Status:** ✅
```

## Troubleshooting

### Dashboard Issue Not Found

Ensure the dashboard issue has the `dashboard` label and is not closed.

### Daily Reports Not Linking

Verify the daily workflow has permissions to comment on issues and the dashboard issue number is correctly referenced.
