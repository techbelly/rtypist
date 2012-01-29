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

  C_ESC_KEY = 27

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

  def display_speed(total_chars,elapsed_time,error_count)
    test_time  = elapsed_time / 60.0
    if (elapsed_time > 0)
      cpm = total_chars / test_time
      adjusted_cpm = (total_chars - (error_count * 5)) / test_time
    end
    line = Ncurses.LINES - 5
    message = " Raw speed      = %6.2f wpm " % (cpm / 5.0)
    Ncurses.move(line,Ncurses.COLS - message.length - 1)
    add_rev(message)
    line += 1
    message = " Adjusted speed = %6.2f wpm " % (adjusted_cpm / 5.0)
    Ncurses.move(line,Ncurses.COLS - message.length - 1)
    add_rev(message)
    line += 1
    message = "            with %.1f%% errors " % ( 100.0 * error_count / total_chars.to_f)
    Ncurses.move(line,Ncurses.COLS - message.length - 1)
    add_rev(message)
    line += 1
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
      when Ncurses::KEY_CANCEL,C_ESC_KEY,'q'.ord, 'Q'.ord
        return up_label
      else
        puts ch
      end
    end while true 
  end

  def do_tutorial(data,command_data,line_num)
    lines = command_data.split("\n")
    line_no = 1
    Ncurses.move(line_no,0); Ncurses.clrtobot
    lines.each_with_index do |l,i|
      Ncurses.move(line_no+i,0)
      Ncurses.addstr(l[2..-1])
    end
    Ncurses.getch
  end

  def do_instruction(data,command_data,i)
    line2 = command_data.split('\n')[0]
    Ncurses.move(1,0); Ncurses.clrtobot
    Ncurses.addstr(data)
    if line2
      Ncurses.move(2,0)
      Ncurses.addstr(line2[2..-1])
    end
  end

  def getch_fl(cursor_char)
    y,x = Ncurses.getcury(@screen), Ncurses.getcurx(@screen)
    if (cursor_char == 0)
      Ncurses.curs_set 0
      Ncurses.refresh
      Ncurses.move(Ncurses.LINES - 1, Ncurses.COLS - 1)
      Ncurses.cbreak
      rc = Ncurses.getch
      Ncurses.move(y,x)
    else
      Ncurses.curs_set 1
      Ncurses.refresh
      Ncurses.cbreak
      rc = Ncurses.getch
      Ncurses.curs_set 0
      Ncurses.refresh
    end
    return rc
  end

  def do_query_repeat
    Ncurses.move(Ncurses.LINES - 1, 0)
    Ncurses.clrtoeol
    Ncurses.move(Ncurses.LINES - 1, Ncurses.COLS - "Query".length - 2)
    add_rev("Query")
    Ncurses.move(Ncurses.LINES - 1, 0)
    add_rev(" Press R to repeat, N for next exercise or E to exit")
    while (true)
      ch = getch_fl(0).chr
      case ch
        when 'R','r'
          break
        when 'N','n'
          break
        when 'E','e'
          break
      end
      Ncurses.move(Ncurses.LINES - 1, 0); Ncurses.clrtoeol
      Ncurses.move(Ncurses.LINES - 1, Ncurses.COLS - "Query".length - 2)
      add_rev("Query")
      Ncurses.move(Ncurses.LINES - 1, 0)
      add_rev(" Press R to repeat, N for next exercise or E to exit")
    end
    Ncurses.move(Ncurses.LINES - 1, 0); Ncurses.clrtoeol
    return ch
  end

  def do_drill(data, command_data,i)
    drill_data = [data]+command_data
    if (@last_command == C_TUTORIAL)
      Ncurses.move(1,0); Ncurses.clrtobot
    end
    all_data = drill_data.join("\n")
    pos = 0
    while (true)
      linenum = 4
      Ncurses.move(linenum,0); Ncurses.clrtobot
      drill_data.each do |line|
        Ncurses.addstr(line)
        linenum += 2
        Ncurses.move(linenum,0)
      end
      Ncurses.move(Ncurses.LINES - 1 , Ncurses.COLS - "Drill".length - 2)
      add_rev("Drill")
      linenum = 4+1
     
      Ncurses.move(linenum,0)

      start_time = nil
      chars_typed = 0
      errors = 0
      error_sync = 0
      chars_typed_in_line = 0
      position = 0
      while position < all_data.length
        begin
          rc = getch_fl(" ".ord)
        end while (rc == Ncurses::KEY_BACKSPACE)

        if (chars_typed == 0)
          start_time = Time.new
        end

        chars_typed += 1
        error_sync -= 1

        break if rc == C_ESC_KEY 

        if rc == all_data[position].ord
          Ncurses.addch(rc)
          chars_typed_in_line += 1
        else
          if error_sync >= 0 && rc == all_data[position-1].ord
            next
          elsif chars_typed_in_line < Ncurses.COLS
            add_rev('^')
            chars_typed_in_line += 1
          end
          errors += 1
          error_sync = 1
          if rc == all_data[position+1]
            Ncurses.ungetch(rc)
            error_sync += 1
          end
        end
        if (all_data[position] == "\n")
          linenum += 2
          Ncurses.move linenum, 0
          chars_typed_in_line = 0
        end
        position = position + 1
      end
      if (rc == C_ESC_KEY) 
        next unless chars_typed == 1
      end
      if (rc != C_ESC_KEY)
        end_time = Time.new
        display_speed(chars_typed, end_time - start_time, errors)
      end
      rc = do_query_repeat
      break if rc == 'E' or rc == 'e' or rc == 'N' or rc == 'n'
    end
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
        when C_TUTORIAL
          command_data = buffer_data(file,i)
          do_tutorial(data,command_data,i)
        when C_INSTRUCTION
          command_data = buffer_data(file,i)
          do_instruction(data,command_data,i)
        when C_DRILL
          command_data = buffer_data(file,i).split("\n").map {|s| s[2..-1] }
          do_drill(data,command_data,i)
         when C_SPEEDTEST
          command_data = buffer_data(file,i).split("\n").map {|s| s[2..-1] }
          do_drill(data,command_data,i)
        when C_CONT
          
        else
          puts "Command #{line} at #{i}"
          break;
      end
      unless [C_CONT,C_LABEL,C_CLEAR].include? command
         @last_command = command
      end
    end
  end

  def banner(text)
    text = text.strip
    brand = " rtypist #{Rtypist::VERSION} "
    cols = Ncurses.COLS
    brand_pos = cols - brand.length
    text_pos = ((cols-brand.length) > text.length) ? (cols - brand.length - text.length) / 2 : 0
    Ncurses.move(TOP, 0)
    Ncurses.attron(Ncurses.COLOR_PAIR(C_BANNER))    
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
