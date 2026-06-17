# Personal Scripts

Command-line utilities for development, system maintenance, and photo organization.

Each script contains its own documentation (summary, usage, and requirements) at the top of the file.

## Structure

```
scripts/
├── git-github/          # Repository sync and access auditing
│   ├── update_repos.ps1
│   └── audit_access.ps1
├── cleanup/             # Docker and project artifact cleanup
│   ├── clean-docker.cmd
│   ├── clean-docker.ps1
│   └── purge_projects.ps1
├── photos/              # Photo organization and renaming
│   ├── photos_in_folders.py
│   ├── rename.py
│   └── rename_remove_result.py
└── README.md
```

## Quick reference

| Script | Purpose |
|--------|---------|
| `git-github/update_repos.ps1` | Sync all Git repos under a path (`git fetch` + `git pull`) |
| `git-github/audit_access.ps1` | List GitHub collaborators per repo |
| `cleanup/clean-docker.ps1` / `.cmd` | Remove orphaned Docker resources |
| `cleanup/purge_projects.ps1` | Delete `node_modules`, `vendor`, `venv`, etc. |
| `photos/photos_in_folders.py` | Organize photos into `YYYYMM/YYYYMMDD` folders |
| `photos/rename.py` | Strip `_<number>_...` suffix from `.jpg` names |
| `photos/rename_remove_result.py` | Strip a processed-photo suffix from `.jpg` names |

For usage details, open the script or run `Get-Help .\path\to\script.ps1` (PowerShell).
