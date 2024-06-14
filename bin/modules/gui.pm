package gui;

use strict;
use warnings;
use Exporter 'import';
use Tk;
use Tk::Web;
use Tk::Canvas;
use File::Spec;
use Win32::API; # For F.lux integration (Windows)
use Log::Log4perl;

our @EXPORT = qw(run_gui play_midi apply_theme);

my $logger = Log::Log4perl->get_logger();

# --- GUI Constants ---
my $WINDOW_WIDTH = 800;
my $WINDOW_HEIGHT = 600;
my $FONT = "Comic Sans MS 12"; # Default font
my $THEME = 'default'; # Default theme

# --- Images and Assets ---
my $icon_file = 'images/unmake_icon.ico';
my $hammer_night_image;
my $octopus_dawn_image;
my $thundercloud_image; 
my @octopus_splash_images;

# --- Global Variables ---
my $mw;
my $webamp; 

# --- GUI Initialization ---

sub run_gui {
    # Initialize the main window
    $mw = MainWindow->new;
    $mw->title("Unmake: The Symbolic Link Slayer");
    $mw->geometry("$WINDOW_WIDTH x $WINDOW_HEIGHT");

    # Set default font for the application
    $mw->optionAdd("*Font", $FONT);

    # Load images
    load_images(); 

    # Create and pack the Webamp widget
    $webamp = $mw->Web(-width => 600, -height => 400)->pack;
    $webamp->Load('https://webamp.org/'); 

    # Theme Selection
    create_theme_menu();

    # Create buttons (use pack or grid geometry manager as needed)
    my $rename_button = $mw->Button(-text => "Rename", -command => \&rename_action)->pack;
    my $move_button = $mw->Button(-text => "Move", -command => \&move_action)->pack;
    my $dragonfruit_button = $mw->Button(-text => "Dragonfruit", -command => \&dragonfruit_action)->pack;

    # Baby Squid Cursor (on the main window)
    create_baby_squid_cursor();

    # Easter Egg: Thundercloud Octopus 
    create_easter_egg();

    # F.lux Integration (Windows)
    integrate_flux();

    MainLoop;
}

# --- Helper Functions ---

sub load_images {
    $hammer_night_image = $mw->Photo(-file => 'images/hammer_night.png');
    $octopus_dawn_image = $mw->Photo(-file => 'images/octopus_dawn.png');
    $thundercloud_image = $mw->Photo(-file => 'images/thundercloud.png');

    for my $i (1..5) {  
        push @octopus_splash_images, $mw->Photo(-file => "images/octopus_splash_$i.png");
    }
}

sub create_theme_menu {
    # ... (Implementation for theme selection - dropdown or radio buttons) ...
    # Update $THEME when a theme is selected
}

sub apply_theme {
    # ... (Implementation to apply the selected theme - colors, font) ...
}

sub play_midi {
    # ... (Implementation to load and play the MIDI file in Webamp) ...
    my $midi_file = File::Spec->catfile(File::Spec->curdir(), "unmake_symphony.mid");
    $webamp->Eval("Webamp.loadAndPlay('$midi_file');");
}

sub rename_action {
    # ... (Call the rename_file function from file_ops.pm) ...
    # ... (Call music::compose_midi to generate MIDI)
    # ... (Call play_midi to play the music) 
}

sub move_action {
    # ... (Call the move_file function from file_ops.pm) ...
    # ... (Call music::compose_midi to generate MIDI)
    # ... (Call play_midi to play the music)
}

sub dragonfruit_action {
    # ... (Call the find_and_destroy_culprits function from file_ops.pm) ...
    # ... (Call music::compose_midi to generate MIDI)
    # ... (Call play_midi to play the music)
}

# --- Cursor Magic ---

sub create_baby_squid_cursor {
    my $canvas = $mw->Canvas(-width => 32, -height => 32, -bd => 0, -highlightthickness => 0)->pack;
    my $squid_image = $canvas->createImage(0, 0, -image => 'images/baby_squid.png', -anchor => 'nw'); 

    $canvas->bind('<Motion>', sub {
        my ($x, $y) = @_;
        $canvas->coords($squid_image, $x, $y);
    });

    # ... (Optional: Add animation logic for the tentacle)
}

# --- Easter Egg Extravaganza! ---

sub create_easter_egg {
    my $canvas = $mw->Canvas(-width => $WINDOW_WIDTH, -height => $WINDOW_HEIGHT, -bd => 0, -highlightthickness => 0)->pack;
    my $thundercloud = $canvas->createImage(
        $WINDOW_WIDTH / 2, 50,  
        -image => $thundercloud_image, 
        -anchor => 'center',
        -state => 'hidden'  # Initially hidden
    );

    # ... (Bind a secret key combination to trigger the animation) ...

    sub run_easter_egg_animation {
        $canvas->itemconfigure($thundercloud, -state => 'normal'); 

        # ... (Add animation logic for the thundercloud - flashing, movement, etc.)

        # ... (After a delay, animate the octopus splash images)

        $mw->after(5000, sub {  # Example: Hide after 5 seconds
            $canvas->itemconfigure($thundercloud, -state => 'hidden');
            # ... (Hide octopus images) ...
        });
    }
}

# --- F.lux Integration (Windows) ---

sub integrate_flux {
    if ($Config{osname} =~ /win/i) {
        my $flux_api = Win32::API->new('flux.dll', 'GetColorTemp', 'I', 'I');

        $mw->repeat(60000, sub { # Check every minute
            my $color_temp = $flux_api->Call(0); 
            if ($color_temp < 4000) { # Example: Below 4000K is "night"
                # ... (Apply night theme or update logo) ... 
            } else {
                # ... (Apply day theme or update logo) ... 
            }
        });
    }
}

1; 