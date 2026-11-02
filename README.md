![Zero-Trust Vault](docs/assets/vault-header.svg)

# Zero-Trust Vault

Local Ubuntu demonstration of student file access, canary monitoring and verified recovery.

**Run:** Open Ubuntu with systemd enabled. From this folder, run `sudo bash run.sh`, then open **http://localhost:8765**. Keep the terminal open. Press Ctrl+C to stop the dashboard.

**Demo:** Under Defense & recovery, select Backup / verify before editing and enable monitoring. Save a sentence in Student workspace. Simulate an incident with `DEMO`, check that writing is blocked, then recover with `RESTORE`. Activity shows the event history.

**Submission:** [Report](submission/Project_Report.pdf) · [Presentation](submission/Project_Presentation.pptx) · [Screenshots](submission/screenshots/)

The launcher reuses an existing vault. On a fresh Ubuntu lab system it creates the demo users and storage. Recovery returns the active files to the clean backup state.

**Team:** Dharshini K, Kani V, Hemanath K and Ibadul Azam.
