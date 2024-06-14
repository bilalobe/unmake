package file_ops;

use strict;
use warnings;
use Exporter 'import';
use File::Spec;
use File::Basename;
use File::Copy; # For the move operation
use Time::Piece;
use Log::Log4perl; 

our @EXPORT = qw(rename_file move_file find_and_destroy_culprits);

my $logger = Log::Log4perl->get_logger();

# --- File Operations ---

sub rename_file {
    my ($file_path) = @_;

    # 1. Check if the file exists
    if (! -e $file_path) {
        $logger->error("File not found: $file_path");
        return "Error: File not found: $file_path\n";
    }

    # 2. Get original file name (example using timestamps)
    my $original_name = get_original_name($file_path);

    if (defined $original_name) {
        my $new_path = File::Spec->catfile(File::Spec->dirname($file_path), $original_name);

        # 3. Rename the file
        if (rename($file_path, $new_path)) {
            $logger->info("File renamed: $file_path -> $new_path");
            return "File renamed successfully.\n";
        } else {
            $logger->error("Failed to rename: $file_path -> $new_path: $!");
            return "Error: Failed to rename file.\n";
        }
    } else {
        $logger->error("Could not determine original name for: $file_path");
        return "Error: Could not determine the original file name.\n";
    }
}

sub move_file {
    my ($file_path) = @_;

    # 1. Check if the file exists
    if (! -e $file_path) {
        $logger->error("File not found: $file_path");
        return "Error: File not found: $file_path\n";
    }

    # 2. Get original directory
    my $original_dir = get_original_directory($file_path); 

    if (defined $original_dir) {
        my $new_path = File::Spec->catfile($original_dir, File::Spec->basename($file_path));

        # 3. Move the file
        if (move($file_path, $new_path)) {
            $logger->info("File moved: $file_path -> $new_path");
            return "File moved successfully.\n";
        } else {
            $logger->error("Failed to move: $file_path -> $new_path: $!");
            return "Error: Failed to move file.\n";
        }
    } else {
        $logger->error("Could not determine original directory for: $file_path");
        return "Error: Could not determine the original directory.\n";
    }
}

# --- Dragonfruit Functionality ---

sub find_and_destroy_culprits {
    my ($directory) = @_;

    $directory ||= File::Spec->curdir(); # Default to current directory if none provided

    opendir(my $dh, $directory) or die "Couldn't open directory '$directory': $!";
    my @files = readdir($dh);
    closedir($dh);

    for my $file (@files) {
        next if $file =~ /^\.\.?$/; # Skip . and .. 

        my $full_path = File::Spec->catfile($directory, $file);

        if (-l $full_path) { 
            my $target = readlink($full_path);
            $logger->debug("Found symbolic link: $full_path -> $target");

            if (! -e $target) { 
                $logger->info("Deleting broken link: $full_path");
                unlink $full_path or $logger->warn("Could not delete $full_path: $!");
            }
        } elsif (-d $full_path) {
            find_and_destroy_culprits($full_path);
        }
    }

    return "Dragonfruit has cleansed the directory of broken links!\n";
}

# --- Helper Functions  ---

sub get_original_name {
    my ($file_path) = @_;

    my $timestamp = (stat($file_path))[9]; # Get the file's modification timestamp
    my $original_name = localtime($timestamp)->strftime("%Y%m%d%H%M%S"); # Format the timestamp as desired

    return $original_name;
}

sub get_original_directory {
    my ($file_path) = @_;

    # ... (Implement logic to determine the original directory)
    # You might use a log file or a database to track file moves.

    my $original_dir = File::Spec->curdir(); # Default to current directory

    return $original_dir; 
}
1;