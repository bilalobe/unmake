#!/usr/bin/perl 

# The Unmake Symphony: Where File Operations Dance to a Retro Beat 

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use Log::Log4perl;
use File::Basename;
use Config;

# Import our custom modules
use file_ops; 
use cron_manager;
use gui; 
use music; 

# --- Configuration ---
Log::Log4perl->easy_init({
    level   => $DEBUG,
    file    => ">unmake.log"
});
my $logger = Log::Log4perl->get_logger();

my %sound_effects = (
    'rename_success'      => 'sounds/trumpet_fanfare.mp3',
    'move_success'        => 'sounds/chime.wav',
    'dragonfruit_success' => 'sounds/flute_trill.mp3',
    'error'               => 'sounds/gong.wav',
    # Add more sounds as needed
);

# --- Command-line Arguments ---
my $action; 
my $file_path;
my $cron_action; 
my $cron_time;
my $theme = 'default'; # Default theme 
my $help; 

GetOptions (
    "action=s"      => \$action,
    "file=s"        => \$file_path,
    "cron-action=s" => \$cron_action,
    "cron-time=s"   => \$cron_time, 
    "theme=s"       => \$theme,
    "help"          => \$help,
);

# --- Help Message ---
if ($help) {
    print_usage(); 
    exit;
}

# --- Error Handling for Missing Arguments ---
if (!$action || (!$file_path && $action ne 'cron')) {
    handle_error("Missing required arguments. Use --help for usage information.");
    exit;
}

# --- Action Handling --- 

if ($action eq 'rename') {
    my $result = file_ops::rename_file($file_path);
    print $result; 
    music::compose_midi($theme);
    gui::play_midi();
} elsif ($action eq 'move') {
    my $result = file_ops::move_file($file_path);
    print $result; 
    music::compose_midi($theme);
    gui::play_midi();
} elsif ($action eq 'cron') {
    my $result = handle_cron_tasks(); 
    print $result; 
} elsif ($action eq 'dragonfruit') {
    my $result = file_ops::find_and_destroy_culprits($file_path);
    print $result;
    music::compose_midi($theme);
    gui::play_midi();
} else {
    handle_error("Invalid action specified.");
}

# --- Helper Functions ---

sub print_usage {
    print <<'EOUSAGE';
Usage: unmake.pl --action=[rename|move|cron|dragonfruit] --file="file_path" [options]

Unmake: The maestro of file operations, conducting a symphony of order in your system. 

Actions:

  rename:    Undo a file rename, restoring its original name.
  move:      Undo a file move, returning it to its former location.
  cron:      Manage scheduled tasks (list, add, remove).
             Use with --cron-action=[list|add|remove] and --cron-time="time_spec" 
  dragonfruit: Seek and destroy broken symbolic links.

Options: 

  --file="file_path":  The path to the file or directory.
  --cron-action:        Action for cron jobs (list, add, remove).
  --cron-time:          Time specification for cron jobs (e.g., "0 0 * * *").
  --theme:              Select a theme (default, epic, mysterious).
  --help:              Display this enchanting help message. 

EOUSAGE
}

sub handle_error {
    my ($error_message) = @_;
    $logger->error($error_message);
    print "Error: $error_message\n";
    play_sound($sound_effects{'error'});
}

sub play_sound {
    my ($sound_file) = @_;
    system("foobar2000 \"$sound_file\" --play-and-exit") == 0 
        or $logger->warn("Could not play sound: $sound_file"); 
}

sub handle_cron_tasks {
    if ($cron_action eq 'list') {
        return cron_manager::list_scheduled_tasks();
    } elsif ($cron_action eq 'add' && $cron_time) {
        return cron_manager::add_scheduled_task($cron_time, File::Spec->rel2abs($0)); 
    } elsif ($cron_action eq 'remove') {
        return cron_manager::remove_scheduled_task(File::Spec->rel2abs($0)); 
    } else {
        $logger->error("Invalid cron action or missing arguments.");
        return "Error: Invalid cron action or missing arguments.\n";
    }
}

# Start the GUI
gui::run_gui();

$logger->info("Script execution complete.");