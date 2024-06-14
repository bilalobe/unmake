package cron_manager; 

use strict;
use warnings;
use Exporter 'import';
use Config;
use File::Spec;
use File::Basename; 
use IPC::Open3;
use Win32::OLE;
use Log::Log4perl; 

our @EXPORT = qw(
    list_scheduled_tasks 
    add_scheduled_task 
    remove_scheduled_task
);

my $logger = Log::Log4perl->get_logger();

# Platform Detection
sub is_windows {
    return $Config{osname} =~ /win/i;
}

# Centralized Task Management Functions 
sub list_scheduled_tasks {
    if (is_windows()) {
        return list_windows_tasks();
    } else {
        return list_unix_cron_jobs();
    }
}

sub add_scheduled_task {
    my ($time, $script_path) = @_;
    if (is_windows()) {
        return add_windows_task($time, $script_path);
    } else {
        return add_unix_cron_job($time, $script_path);
    }
}

sub remove_scheduled_task {
    my ($script_path) = @_;
    if (is_windows()) {
        return remove_windows_task($script_path);
    } else {
        return remove_unix_cron_job($script_path);
    }
}

# ---- Unix-like Crontab Functions ----

sub list_unix_cron_jobs {
    my $output = `crontab -l 2>&1`;
    if ($? == 0) {
        return $output;
    } else {
        $logger->error("Error listing cron jobs: $output");
        return "Error: Could not list cron jobs.\n";
    }
}

sub add_unix_cron_job {
    my ($time, $script_path) = @_;
    my $command = "/usr/bin/perl $script_path"; 
    my $cron_entry = "$time $command";

    # Use IPC::Open3 to interact with crontab
    my ($in, $out, $err);
    my $pid = open3($in, $out, $err, 'crontab', '-');
    print $in "$cron_entry\n"; 
    close($in);
    waitpid($pid, 0);

    if ($? == 0) {
        $logger->info("Cron job added: $cron_entry");
        return "Cron job added successfully.\n";
    } else {
        my $error_output = join "", ; 
        $logger->error("Error adding cron job: $error_output");
        return "Error: Could not add cron job.\n";
    }
}

sub remove_unix_cron_job {
    my ($script_path) = @_;
    my $command = "/usr/bin/perl $script_path";
    my $output = `crontab -l 2>&1`;

    if ($? != 0 && $output !~ /no crontab for/) {
        $logger->error("Error fetching current cron jobs: $output");
        return "Error: Could not fetch current cron jobs.\n";
    }

    my @lines = split /\n/, $output;
    @lines = grep { $_ !~ /\Q$command\E/ } @lines; 

    # Use a temporary file to update crontab
    my ($fh, $filename) = tempfile();
    print $fh join("\n", @lines) . "\n";
    close $fh;

    my $result = `crontab $filename 2>&1`;
    unlink $filename; 

    if ($? == 0) {
        $logger->info("Cron job removed: $command");
        return "Cron job removed successfully.\n";
    } else {
        $logger->error("Error removing cron job: $result");
        return "Error: Could not remove cron job.\n";
    }
}

# ---- Windows Task Scheduler Functions ----

sub list_windows_tasks {
    my $scheduler = Win32::OLE->new('Schedule.Service') || die "Could not create Schedule.Service object";
    $scheduler->Connect();
    my $rootFolder = $scheduler->GetFolder('\\');

    my $tasks = $rootFolder->GetTasks(0);
    foreach my $task (in $tasks) {
        print "Task Name: ", $task->{Name}, "\n";
        print "Path: ", $task->{Path}, "\n";
    }
}

sub add_windows_task {
    my ($time) = @_;
    my ($hour, $minute) = split /:/, $time;
    my $scheduler = Win32::OLE->new('Schedule.Service') || die "Could not create Schedule.Service object";
    $scheduler->Connect();
    my $rootFolder = $scheduler->GetFolder('\\');

    my $taskDefinition = $scheduler->NewTask(0);
    my $settings = $taskDefinition->Settings;
    $settings->StartWhenAvailable = 1;

    my $triggerCollection = $taskDefinition->Triggers;
    my $trigger = $triggerCollection->Create(1);
    $trigger->StartBoundary = sprintf("2023-01-01T%02d:%02d:00", $hour, $minute);

    my $actionCollection = $taskDefinition->Actions;
    my $execAction = $actionCollection->Create(0);
    $execAction->Path = $^X; # Perl interpreter
    $execAction->Arguments = File::Spec->rel2abs($0);

    $rootFolder->RegisterTaskDefinition(
        "UnmakeTask", $taskDefinition, 6, undef, undef, 3, undef
    );

    print "Task scheduled successfully.\n";
}

sub remove_windows_task {
    my $scheduler = Win32::OLE->new('Schedule.Service') || die "Could not create Schedule.Service object";
    $scheduler->Connect();
    my $rootFolder = $scheduler->GetFolder('\\');

    eval {
        $rootFolder->DeleteTask("UnmakeTask", 0);
        print "Task removed successfully.\n";
    };
    if ($@) {
        $logger->error("Error removing task: $@");
        print "Error: Could not remove task.\n";
    }
}

1;