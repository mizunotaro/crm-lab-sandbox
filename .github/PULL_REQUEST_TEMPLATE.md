## Summary (EN+JP)
[One sentence description of the change]

**Japanese:** [1行で変更内容を説明してください]

## Motivation
Why is this change needed? What problem does it solve?

## Scope
What areas does this change affect? (e.g., frontend, backend, docs, CI/CD)

## Verification Evidence

### Checklist
- [ ] All acceptance criteria from issue are met
- [ ] Lint passes (frontend + backend, if applicable)
- [ ] Unit tests pass
- [ ] Integration tests pass (if applicable)
- [ ] API contract checks pass (if applicable)
- [ ] Database migrations validated (if applicable)
- [ ] License scan passes (OSS compliance)
- [ ] Security checks pass (dependency vulnerabilities)
- [ ] Documentation updated (docs/ and README if needed)
- [ ] No secrets leaked (no .env files, credentials, tokens)

### How to Test
```bash
# Example commands to verify this change locally
npm run test
npm run lint
# or
pytest tests/
# etc.
```

### CI Link
[Link to CI run showing all checks passing]

## Screenshots (for UI changes)
[If applicable, attach screenshots or GIFs showing before/after]

## Risks and Rollback

### Risks
- [ ] Breaking changes: Yes / No
- [ ] Data loss risk: Yes / No
- [ ] Performance impact: Yes / No
- [ ] Other risks: [describe]

### Rollback Plan
If this change causes issues, how do we revert?

1. [Rollback step 1 - e.g., revert commit]
2. [Rollback step 2 - e.g., database migration rollback]
3. [Rollback step 3 - if applicable]

### Dependencies
- [ ] New dependencies added? (requires ADR in docs/ai/decisions/)
- [ ] Dependency version changes? (specify versions)

## References
- Closes #<issue_number>
- Related: #<issue_number> or PR #<pr_number>

## AI Session Log
- Session log: `docs/ai/session-log/YYYYMMDD_HHMM.md` (required for AI-generated changes)
- ADR: `docs/ai/decisions/ADR-XXXX-*.md` (if architecture decision made)
