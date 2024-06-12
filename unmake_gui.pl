use Tk;

# Create the main application window
my $mw = MainWindow->new;
$mw->title("Unmake: The Symbolic Link Slayer");
$mw->geometry("400x200");

# Create a frame to hold the widgets
my $frame = $mw->Frame()->pack(-fill => 'both', -expand => 1);

# Theme Selection
my $theme_label = $frame->Label(-text => "Choose a Theme:")->pack(-side => 'top');
my @theme_choices = qw(Default Epic Mysterious);
my $theme_choice = $frame->Optionmenu(-options => \@theme_choices)->pack(-side => 'top');

# Dragonfruit Checkbox
my $dragonfruit_checked = 0;
my $dragonfruit_checkbox = $frame->Checkbutton(-text => "Enable Dragonfruit Mode",
                                               -variable => \$dragonfruit_checked)->pack(-side => 'top');

# Launch Button
my $launch_button = $frame->Button(-text => "Launch Unmake!",
                                   -command => \&on_launch)->pack(-side => 'top');

# Function to handle the launch button click event
sub on_launch {
    my $selected_theme = $theme_choices[$theme_choice->curselection()];
    my $dragonfruit_mode = $dragonfruit_checked ? "--dragonfruit" : "";

    # Construct the command line arguments
    my $command = "perl unmake.pl --theme='$selected_theme' $dragonfruit_mode";

    # Execute the Perl script
    system($command);
}

# Start the Tk event loop
MainLoop;
