$taskName = "{put task name}";
$currentTask = Get-ScheduledTask -TaskName $taskName;
$settings = $currentTask.Settings;
$settings.Priority = 4 ;
Set-ScheduledTask -TaskName $taskName -TaskPath $currentTask.TaskPath -Settings $settings -User "{put user}" -Password "{put password}"