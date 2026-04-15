# Contributing to Crisis Command Center

## Project Philosophy

**Simple. Fast. Terminal-first.**

Crisis Command Center is designed for on-call engineers who need answers in seconds, not minutes. We prioritize:

1. **Speed** — Dashboard loads in <1 second
2. **Clarity** — One screen, all the context
3. **Actionability** — One-click commands, not copy-paste

## How to Contribute

### Bug Reports

Open an issue with:
- What you were doing
- What happened
- What you expected to happen
- Output of `bash scripts/launch-dashboard.sh --version` (when implemented)

### Feature Requests

Open an issue with:
- Use case: "I was on-call and..."
- Problem: "I couldn't quickly find..."
- Solution: "It would be great if..."

### Code Contributions

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test: `bash scripts/launch-dashboard.sh INC-XXX`
5. Commit: `git commit -m "Add your feature"`
6. Push: `git push origin feature/your-feature`
7. Open a PR

## Coding Standards

- **Shell scripts:** Bash, compatible with bash 5.0+
- **Markdown:** GitHub-flavored
- **Indentation:** 4 spaces (shell), 2 spaces (Markdown)
- **Comments:** Explain WHY, not WHAT
- **Error handling:** `set -e` at the top, meaningful error messages

## Testing

- Test on Linux (Ubuntu 20.04+)
- Test on macOS (12+)
- Test with no incident replay engine (graceful degradation)
- Test with empty context graph (graceful degradation)

## Areas to Contribute

### Priority 1
- [ ] Fix alert type extraction in similar-incidents.sh (currently broken)
- [ ] Add unit tests for scripts
- [ ] Add Dockerfile for containerized deployment

### Priority 2
- [ ] Web UI (React/Next.js)
- [ ] Semantic similarity search (vector embeddings)
- [ ] AI assistant integration

### Priority 3
- [ ] Slack/PagerDuty integration
- [ ] Multi-cluster support
- [ ] Pattern detection (cross-incident analysis)

## License

All contributions are licensed under MIT.
