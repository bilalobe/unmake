require 'wx'

class UnmakeGUI < Wx::App
  public :main_loop

  def on_init
    frame = UnmakeFrame.new
    frame.show
    true
  end
end

class UnmakeFrame < Wx::Frame
  def initialize
    super(nil, -1, 'Unmake: The Symbolic Link Slayer', size: [400, 200])

    panel = Wx::Panel.new(self)
    sizer = Wx::BoxSizer.new(Wx::VERTICAL)

    # Theme Selection
    theme_label = Wx::StaticText.new(panel, -1, 'Choose a Theme:')
    sizer.add(theme_label, 0, Wx::ALL | Wx::ALIGN_CENTER_HORIZONTAL, 5)

    theme_choices = ['Default', 'Epic', 'Mysterious']
    @theme_choice = Wx::Choice.new(panel, -1, choices: theme_choices)
    @theme_choice.set_selection(0)  # Set default theme
    sizer.add(@theme_choice, 0, Wx::ALL | Wx::EXPAND, 5)

    # Dragonfruit Checkbox
    @dragonfruit_checkbox = Wx::CheckBox.new(panel, -1, 'Enable Dragonfruit Mode')
    sizer.add(@dragonfruit_checkbox, 0, Wx::ALL | Wx::ALIGN_CENTER_HORIZONTAL, 5)

    # Launch Button
    launch_button = Wx::Button.new(panel, -1, 'Launch Unmake!')
    evt_button(launch_button.get_id) { |event| on_launch }
    sizer.add(launch_button, 0, Wx::ALL | Wx::EXPAND, 5)

    panel.set_sizer(sizer)
  end

  def on_launch
    selected_theme = @theme_choice.get_string_selection
    dragonfruit_mode = @dragonfruit_checkbox.is_checked ? '--dragonfruit' : ''
    
    # Construct the command line arguments
    command = "perl unmake.pl --theme='#{selected_theme}' #{dragonfruit_mode}"

    # Execute the Perl script
    system(command)
  end
end

app = UnmakeGUI.new
app.main_loop
