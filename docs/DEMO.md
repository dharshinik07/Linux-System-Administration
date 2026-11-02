# Live demonstration

Start with `sudo ztvault`. If the vault is already locked, recover with option 8 and `RESTORE` before beginning.

| Step | Action | Expected observation |
|---|---|---|
| 1 | Choose 1 | Assignment and fictional marks display |
| 2 | Choose 3 | Student reads; outsider and student backup access are denied |
| 3 | Choose 4 | Clean backup created or existing archive verified |
| 4 | Choose 2, enter `I completed my Linux assignment.` | Update succeeds |
| 5 | Choose 1, then 5 | Sentence appears; canary remains SAFE |
| 6 | Choose 10 | Automatic monitoring enabled |
| 7 | Choose 6, type `DEMO` | Sample canary changes |
| 8 | Press Enter to return to the menu, wait about 15 seconds | Timer has an opportunity to check |
| 9 | Choose 7, then 9 | Student write denied; alert visible in log |
| 10 | Choose 8, type `RESTORE` | Archive and sample checksums pass; access reopens |
| 11 | Choose 1, then 5 | Original assignment and SAFE canary |
| 12 | Enter 99 | Invalid menu choice rejected |
| 13 | Choose 2, submit an empty sentence | Blank input rejected |
| 14 | Choose 0 | Interactive menu closes |

The timer can continue after the menu closes. Re-enable it before another automatic-detection demonstration if you stopped it.

## Presenter split

- Dharshini: introduction, problem and architecture.
- Kani: sample files, access tests, backup and normal input.
- Hemanath: canary, systemd monitoring and containment.
- Ibadul Azam: recovery, input validation, code and conclusion.

## Explanation to remember

Automatic detection and permission-based access blocking are separate from recovery. The administrator starts recovery explicitly. The canary change is harmless test data, not ransomware execution.

## Actual evidence

See `screenshots/README.md`. The recorded DEMO event at 13:37:30 and ALERT at 13:37:34 show a four-second delay in that run only. Do not present it as a guaranteed response time. The option-4 screenshot shows verification of an existing clean backup.
