# Windows Event Log Diff

A read-only PowerShell utility to show new System, Application or Security events since a previous snapshot. Uses event-log record IDs rather than comparing messages.

PowerShell 5.1 or PowerShell 7+ on Windows.

## Usage


```powershell
.\EventLog-Diff.ps1 -LogName System
.\EventLog-Diff.ps1 -LogName System -MaxEvents 1000
.\EventLog-Diff.ps1 -LogName Application -ReportPath '.\out\application-events.json'
```

The first run saves a baseline under `snapshots/`; later runs show only events with newer record IDs. Snapshots are separate for each log and can be relocated with `-SnapshotPath`.

If the event log appears to have been cleared or replaced, the script warns and starts a new baseline. When the event limit is reached, it warns that older new events may have been omitted. It never changes the Windows Event Log itself.

For Security logs, permissions may require an elevated terminal. Do not post detailed event messages publicly without reviewing them: they can contain usernames, hostnames and other private details.
