# Release Notes Template

Use this template to create release notes for merged PRs, especially for AI-generated changes.

---

## Release Information

- **Version:** [x.y.z or PR#]
- **Date:** YYYY-MM-DD
- **Status:** Draft | Published
- **Release Type:** Patch | Minor | Major | Breaking Change

---

## Summary

Brief 2-3 sentence summary of what was changed in this release.

---

## Changes

### Features Added
- [ ] Feature description
  - Link to PR or Issue

### Bug Fixes
- [ ] Bug description
  - Link to PR or Issue

### Refactoring / Improvements
- [ ] Description of improvement
  - Link to PR or Issue

### Documentation
- [ ] Documentation updates
  - Link to PR or Issue

### Dependencies
- [ ] Dependency changes (if any)
  - Package: old → new version
  - Reason for change

---

## Breaking Changes

> ⚠️ **If this section is not empty, ensure migration steps are provided below**

- [ ] Description of breaking change
  - Impact on users
  - Migration steps required

---

## Risk Assessment

| Risk Level | Description | Mitigation |
|------------|-------------|------------|
| Low | Minimal impact, easily reversible | N/A |
| Medium | Moderate impact, reversible with effort | [Mitigation steps] |
| High | High impact, difficult to reverse | [Mitigation steps] |

---

## Rollback Plan

If this release causes issues, follow these steps:

1. **Immediate Actions:**
   - [ ] Step 1: Revert PR or rollback deployment
   - [ ] Step 2: Verify system stability

2. **Commands (if applicable):**
   ```bash
   # Add rollback commands here
   ```

3. **Verification:**
   - [ ] Check that services are healthy
   - [ ] Run smoke tests
   - [ ] Verify data integrity (if DB changes)

---

## Migration Steps

> Only fill this section if breaking changes are present

1. **Pre-migration:** [Actions to take before migration]
2. **Migration:** [Steps to perform migration]
3. **Post-migration:** [Actions to take after migration]
4. **Validation:** [How to verify migration success]

---

## Verification

### CI Status
- [ ] All CI checks passed
- [ ] Link to CI run: [GitHub Actions link]

### Testing Evidence
- [ ] Unit tests: [Coverage % or test count]
- [ ] Integration tests: [Status]
- [ ] E2E tests: [Status]
- [ ] Manual testing: [Summary of manual tests performed]

### Deploy Verification
- [ ] Feature tested in [staging/production]
- [ ] Monitoring checks: [Status]
- [ ] Error rates: [Within baseline]

---

## Related Issues & PRs

| Type | Number | Title | Status |
|------|--------|-------|--------|
| Issue | #123 | Issue title | Open/Closed |
| PR    | #456  | PR title   | Merged |

---

## Known Issues

| Issue | Description | Workaround |
|-------|-------------|------------|
| #123  | Description | Workaround |

---

## Notes

Additional context, acknowledgments, or special notes for this release.

---

## References

- [Link to related documentation](docs/...)
- [Link to design spec](docs/...)
- [Link to previous release notes](docs/ops/release-notes-vX.Y.Z.md)
