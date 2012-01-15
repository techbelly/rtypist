require 'ncursesw'

class Rtypist::Application

  TOP = 0

  C_NORMAL = 1
  C_BANNER = 2
  C_PROG_NAME = 3
  C_PROG_VERSION = 4
  C_MENU_TITLE = 5

  C_COMMENT                 = '#'
  C_ALT_COMMENT             = '!'
  C_SEP                     = ':'
  C_CONT                    = ' '
  C_LABEL                   = '*'
  C_TUTORIAL                = 'T'
  C_INSTRUCTION             = 'I'
  C_CLEAR                   = 'B'
  C_GOTO                    = 'G'
  C_EXIT                    = 'X'
  C_QUERY                   = 'Q'
  C_YGOTO                   = 'Y'
  C_NGOTO                   = 'N'
  C_DRILL                   = 'D'
  C_DRILL_PRACTICE_ONLY     = 'd'
  C_SPEEDTEST               = 'S'
  C_SPEEDTEST_PRACTICE_ONLY = 's'
  C_KEYBIND                 = 'K'
  C_ERROR_MAX_SET           = 'E'
  C_ON_FAILURE_SET          = 'F'
  C_MENU                    = 'M'

  def initialize(options = {})
    @options = options
    @labels = {}
  end

  def add_rev str
     Ncurses.attron(Ncurses::A_REVERSE);
     Ncurses.addstr str;
     Ncurses.attroff(Ncurses::A_REVERSE);
  end

  def command_lines(file,start=0)
    File.open(file).each_with_index do |line,i|
      next if i < start
      l = line.chomp
      next if l.length == 0 || l[0] == C_COMMENT || l[0] == C_ALT_COMMENT
      yield l,i 
    end
  end

  def buffer_data(file,command_start)
    data_start = command_start +1
    data = []
    File.open(file).each_with_index do |line, i|
      next if i < data_start
      break if line[0] != C_CONT
      data << line
    end
    return data.join
  end

  def labels(file)
    command_lines(file) do |line,i|
      yield line,i if line[0] == C_LABEL 
    end
  end

  def build_label_index(file)
    labels(file) do |line,i| 
      label = line.split(":")[1]
      @labels[label] = i
    end
  end

  def do_menu(data,command_data,i)
    num_lines = command_data.split("\n").count
    num_items = num_lines - 1;
    menu_height_max = Ncurses.LINES - 6;
    title_r = /\s+(?:UP=([^ ]*) )?\"(.*)\"/
    match =title_r.match data
    _,up_label,title = *match
    label_r = / :([^ ]*)\s+\"(.*)\"/
    labels = command_data.split("\n").map { |l| 
      m = label_r.match(l)
      [m[1],m[2]]
    }
    
    max_width = labels.map { |l| l[1].length }.max
    columns = Ncurses.COLS / (max_width + 2)
    while (columns > 1 && num_items / columns <= 3)
      columns = columns - 1
    end

    items_first_column = num_items/columns;
    if (num_items % columns != 0)
      items_first_column = items_first_column + 1
    end

    if (items_first_column > menu_height_max)
      start_y = 4
    else
      start_y = (Ncurses.LINES - items_first_column) / 2
    end

    spacing = (Ncurses.COLS - columns * max_width) / (columns + 1)

    items_per_page = [num_items, columns * [menu_height_max,items_first_column].min].min
    
    real_items_per_column = items_per_page / columns
    if (items_per_page % columns != 0)
      real_items_per_column = real_items_per_column + 1
    end

    start_idx = 0
    end_idx = items_per_page - 1

    Ncurses.move(1,0)
    Ncurses.clrtobot

    Ncurses.wattron(@screen, Ncurses::A_BOLD)
    Ncurses.attron(Ncurses.COLOR_PAIR(C_MENU_TITLE));
    Ncurses.mvaddstr(2,(80 - title.length)/ 2, title)
    Ncurses.attron(Ncurses.COLOR_PAIR(C_NORMAL));
    Ncurses.wattroff(@screen, Ncurses::A_BOLD)

    Ncurses.mvaddstr(Ncurses.LINES - 1, 0, "Use arrowed keys to move around, SPACE or RETURN to select and ESCAPE to go back")
    
    ch = nil
    cur_choice = 0
    begin
      columns.times do |i|
        real_items_per_column.times do |j|
          idx = i * real_items_per_column + j + start_idx
          break if idx > end_idx
          if (idx == cur_choice)
            Ncurses.wattron(@screen, Ncurses::A_REVERSE)
          else
            Ncurses.wattroff(@screen, Ncurses::A_REVERSE)
          end
          Ncurses.mvaddstr(start_y+j,(i+1) * spacing + i * max_width, labels[j][1])
          Ncurses.addstr(' ' * (max_width - labels[j][1].length))
        end
      end
      Ncurses.wattroff(@screen, Ncurses::A_REVERSE)
      ch = Ncurses.getch

      case ch
      when Ncurses::KEY_UP,'k'.ord,'K'.ord
        cur_choice = [0, cur_choice -1].max;
        if (cur_choice < start_idx) 
          start_idx = start_idx - 1
          end_idx = end_idx -1
        end
      when Ncurses::KEY_DOWN,'j'.ord,'J'.ord
        cur_choice = [cur_choice +1, num_items -1].min
        if (cur_choice > end_idx)
          start_idx = start_idx + 1
          end_idx = end_idx + 1
        end
      when "\n".ord, " ".ord, Ncurses::KEY_ENTER
        return labels[cur_choice][0] 
      when Ncurses::KEY_CANCEL,27,'q'.ord, 'Q'.ord
        return up_label
      else
        puts ch
      end
    end while true 
  end

  def parse_file(file,label = nil)
    line_no = label ? @labels.fetch(label,0) : 0;
    command_lines(file,line_no) do |line,i|
      command,data = line.split(":")
      case command
        when C_GOTO
          return data
        when C_LABEL
          @last_label = data
        when C_CLEAR
          Ncurses.move(TOP,0); Ncurses.clrtobot
          banner(data);
        when C_MENU
          command_data = buffer_data(file,i)
          return do_menu(data, command_data,i)
        else
          puts "Command #{line} at #{i}"
          break;
      end
    end
  end

  def banner(text)
    text = text.strip
    brand = " rtypist #{Rtypist::VERSION} "
    cols = Ncurses.COLS
    brand_pos = cols - brand.length
    text_pos = ((cols-brand.length) > text.length) ?
      (cols - brand.length - text.length) / 2 : 0;
    Ncurses.move(TOP, 0);
    Ncurses.attron(Ncurses.COLOR_PAIR(C_BANNER));    
    cols.times {  add_rev ' ' }
    Ncurses.move(TOP, text_pos);
    add_rev(text)
    Ncurses.move(TOP, brand_pos)
    Ncurses.attron(Ncurses.COLOR_PAIR(C_PROG_NAME));
    add_rev(brand);
    Ncurses.refresh();
    Ncurses.attron(Ncurses.COLOR_PAIR(C_NORMAL));
  end

  def script_file
    return File.expand_path(File.dirname(__FILE__)+"/../../lessons/gtypist.typ")
  end

  def start
    @screen = Ncurses.initscr
    begin
      Ncurses.clear
      Ncurses.refresh
      Ncurses.typeahead -1
      Ncurses.noecho
      Ncurses.curs_set 0
      Ncurses.keypad(Ncurses.stdscr,true)         
      Ncurses.raw
      banner("Loading " + File.basename(script_file))
      build_label_index(script_file)
      label = nil
      begin
        label = parse_file(script_file,label)
      end while label
      Ncurses.getch
    ensure
      Ncurses.curs_set 1
      Ncurses.endwin
    end
  end
end
