# Demonstration screenshots

Original Ubuntu screenshots supplied during the project demonstration. Sample documents and marks are fictional. Timestamps and results describe that recorded run.

| Figure | Screenshot | Evidence |
|---|---|---|
| D1 | [d1-ubuntu-environment.png](d1-ubuntu-environment.png) | The terminal identifies Ubuntu 26.04 LTS, a WSL2 kernel and systemd as process 1. |
| D2 | [d2-accounts-permissions-and-filesystem.png](d2-accounts-permissions-and-filesystem.png) | ztv_writer belongs to ztv_access; ztv_outsider has a separate group. The active vault uses group permissions, protected state is root-only and the containing filesystem is ext4. |
| D3 | [d3-main-menu.png](d3-main-menu.png) | sudo ztvault opens the Bash menu. The captured status shows the vault OPEN, a backup present and automatic monitoring ACTIVE. |
| D4a | [d4a-user-input-and-saved-output.png](d4a-user-input-and-saved-output.png) | Option 2 accepts a sentence and confirms the update. Option 1 then displays the same sentence in assignment.txt together with the sample marks. |
| D4b | [d4b-user-input-and-saved-output.png](d4b-user-input-and-saved-output.png) | Figure D4. User input processed and saved in the assignment. |
| D5 | [d5-access-tests.png](d5-access-tests.png) | The student successfully reads the assignment. Both outsider reading and student access to protected backups are denied, with PASS messages for the expected restrictions. |
| D6 | [d6-existing-backup-verification.png](d6-existing-backup-verification.png) | Option 4 finds an existing clean backup. Its archive checksum returns OK, and the script preserves the original. This screenshot proves verification, not a new backup creation in this run. |
| D7 | [d7-normal-integrity-check.png](d7-normal-integrity-check.png) | After the legitimate assignment edit, option 5 reports SAFE. The edit did not change the canary fingerprint. |
| D8a | [d8a-automatic-monitoring.png](d8a-automatic-monitoring.png) | Option 10 confirms automatic checks. The timer status shows the unit enabled and active (waiting), with its next trigger and linked service. |
| D8b | [d8b-automatic-monitoring.png](d8b-automatic-monitoring.png) | Figure D8. Enabled and active systemd monitoring timer. |
| D9 | [d9-safe-incident-simulation.png](d9-safe-incident-simulation.png) | Option 6 accepts the exact word DEMO and confirms that the sample canary changed. The operation is a harmless test modification, not malware execution. |
| D10a | [d10a-automatic-detection-and-containment.png](d10a-automatic-detection-and-containment.png) | The student write attempt is denied. The service journal records ALERT and DEFENSE at 13:37:34 UTC, followed by repeated LOCKED checks. This supports timer-driven detection and containment. |
| D10b | [d10b-automatic-detection-and-containment.png](d10b-automatic-detection-and-containment.png) | Figure D10. Student write denial and service-journal evidence of detection. |
| D11 | [d11-security-event-log.png](d11-security-event-log.png) | The log records DEMO at 13:37:30 and ALERT at 13:37:34, along with earlier updates, automation and recovery events. The observed detection delay in this run was four seconds. |
| D12 | [d12-verified-recovery.png](d12-verified-recovery.png) | Option 8 accepts RESTORE. The archive and sample-file checks return OK. The script reports successful restoration, reopened student access and the protected location of the previous files. |
| D13a | [d13a-restored-original-and-safe-state.png](d13a-restored-original-and-safe-state.png) | The restored assignment no longer contains the sentence added in D4. A subsequent option-5 check reports SAFE, confirming that the restored canary matches the baseline. |
| D13b | [d13b-restored-original-and-safe-state.png](d13b-restored-original-and-safe-state.png) | Figure D13. Original documents restored and canary verification passing. |
| D14a | [d14a-invalid-input-handling.png](d14a-invalid-input-handling.png) | Choice 99 produces a menu-range error. An empty sentence produces a separate validation error. The messages guide the user without accepting invalid input. |
| D14b | [d14b-invalid-input-handling.png](d14b-invalid-input-handling.png) | Figure D14. Invalid menu choice and empty assignment input rejected. |
