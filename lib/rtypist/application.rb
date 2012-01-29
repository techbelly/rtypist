require 'rtypist/screen'

class Rtypist::Application

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

  def display_speed(screen,total_chars,elapsed_time,error_count)
    test_time  = elapsed_time / 60.0
    
    if (elapsed_time > 0.01)
      cpm = total_chars / test_time
      adjusted_cpm = (total_chars - (error_count * 5)) / test_time
    
      messages = [
        "Raw speed      = %6.2f wpm" % (cpm / 5.0),
        "Adjusted speed = %6.2f wpm" % (adjusted_cpm / 5.0),
        "with %.1f%% errors" % ( 100.0 * error_count / total_chars.to_f)
      ]
    
      screen.results_box(messages)
    end
  end

  def do_menu(screen,data,command_data,i)
    num_lines = command_data.split("\n").count
    num_items = num_lines - 1;
    
    menu_height_max = screen.lines - 6;
    title_r = /\s+(?:UP=([^ ]*) )?\"(.*)\"/
    match =title_r.match data
    _,up_label,title = *match
    label_r = / :([^ ]*)\s+\"(.*)\"/
    labels = command_data.split("\n").map { |l| 
      m = label_r.match(l)
      [m[1],m[2]]
    }
    
    max_width = labels.map { |l| l[1].length }.max
    columns = screen.cols / (max_width + 2)
    
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
      start_y = (screen.lines - items_first_column) / 2
    end

    spacing = (screen.cols - columns * max_width) / (columns + 1)

    items_per_page = [num_items, columns * [menu_height_max,items_first_column].min].min
    
    real_items_per_column = items_per_page / columns
    if (items_per_page % columns != 0)
      real_items_per_column = real_items_per_column + 1
    end

    start_idx = 0
    end_idx = items_per_page - 1

    screen.clear_from_line(1)
    screen.add_title(title)
    screen.add_mode("Menu")
    screen.bottom_line("Use arrowed keys to move around, SPACE or RETURN to select and ESCAPE to go back")
    
    ch = nil
    cur_choice = 0
    begin
      columns.times do |i|
        real_items_per_column.times do |j|
          idx = i * real_items_per_column + j + start_idx
          break if idx > end_idx
          
          text_start_y = start_y + j
          text_start_x = (i+1) * spacing + i * max_width
          text =         labels[idx][1]
          
          screen.write_at(max_width, text_start_y,text_start_x,text,(idx == cur_choice))
        end
      end
      ch = screen.getch

      case ch
      when screen.key_up,'k'.ord,'K'.ord
        cur_choice = [0, cur_choice -1].max;
        if (cur_choice < start_idx) 
          start_idx = start_idx - 1
          end_idx = end_idx -1
        end
      when screen.key_down,'j'.ord,'J'.ord
        cur_choice = [cur_choice +1, num_items -1].min
        if (cur_choice > end_idx)
          start_idx = start_idx + 1
          end_idx = end_idx + 1
        end
      when "\n".ord, " ".ord, screen.key_enter
        return labels[cur_choice][0] 
      when screen.key_cancel,C_ESC_KEY,'q'.ord, 'Q'.ord
        return up_label
      end
    end while true 
  end

  def do_tutorial(screen,data,command_data,line_num)
    lines = command_data.split("\n").map {|l| l[2..-1]}
    screen.add_lines(lines,1)
    screen.getch
  end

  def do_instruction(screen,data,command_data,i)
    line2 = command_data.split('\n')[0]
    lines = [data]
    lines = lines + line2[2..-1] if line2
    screen.add_lines(lines,1)
  end

  def do_query_repeat(screen)
    begin 
      screen.add_mode("Query")
      screen.bottom_line(" Press R to repeat, N for next exercise or E to exit")
      ch = screen.getch_fl(0).chr
      case ch
        when 'R','r'
          break
        when 'N','n'
          break
        when 'E','e'
          break
      end
    end while(true)
    screen.bottom_line("")
    return ch
  end

  def do_drill(screen, data, command_data,i)
    drill_data = [data]+command_data
    
    if (@last_command == C_TUTORIAL)
      screen.clear_from_line(1)
    end
    
    all_data = drill_data.join("\n")
    pos = 0
    first_line_line = 4
    
    while (true)      
      screen.clear_from_line(first_line_line)
      screen.add_lines(drill_data,first_line_line,2)
      screen.add_mode("Drill")
      
      linenum = first_line_line+1
      screen.move_to_line(linenum)

      start_time = nil
      chars_typed = 0
      errors = 0
      error_sync = 0
      chars_typed_in_line = 0
      position = 0
      
      while position < all_data.length
        begin
          rc = screen.getch_fl(" ".ord)
        end while (rc == screen.key_backspace)

        if (chars_typed == 0)
          start_time = Time.new
        end

        chars_typed += 1
        error_sync  -= 1

        break if rc == C_ESC_KEY 
        
        previous_character = all_data[position-1]
        current_character  = all_data[position]
        next_character     = all_data[position+1]
        
        if rc.chr == current_character
          screen.addch(rc)
          chars_typed_in_line += 1
        else
          
          if error_sync >= 0 && position > 0 && rc.chr == previous_character
            next
          elsif chars_typed_in_line < screen.cols
            screen.add_rev('^')
            chars_typed_in_line += 1
          end
          
          errors += 1
          error_sync = 1
          
          if position < all_data.length && rc.chr == next_character
            screen.ungetch(rc)
            error_sync += 1
          end
        end
        
        if (all_data[position] == "\n")
          linenum += 2
          screen.move_to_line linenum
          chars_typed_in_line = 0
        end
        
        position = position + 1
      end
      if (rc == C_ESC_KEY) 
        next unless chars_typed == 1
      end
      if (rc != C_ESC_KEY)
        end_time = Time.new
        display_speed(screen, chars_typed, end_time - start_time, errors)
      end
      rc = do_query_repeat(screen)
      break if rc == 'E' or rc == 'e' or rc == 'N' or rc == 'n'
    end
  end

  def parse_file(screen,file,label = nil)
    line_no = label ? @labels.fetch(label,0) : 0;
    command_lines(file,line_no) do |line,i|
      command,data = line.split(":")
      case command
        when C_GOTO
          return data
        when C_LABEL
          @last_label = data
        when C_CLEAR
          screen.clear_from_line(0)
          screen.banner(data);
        when C_MENU
          command_data = buffer_data(file,i)
          return do_menu(screen,data, command_data,i)
        when C_TUTORIAL
          command_data = buffer_data(file,i)
          do_tutorial(screen,data,command_data,i)
        when C_INSTRUCTION
          command_data = buffer_data(file,i)
          do_instruction(screen,data,command_data,i)
        when C_DRILL
          command_data = buffer_data(file,i).split("\n").map {|s| s[2..-1] }
          do_drill(screen,data,command_data,i)
         when C_SPEEDTEST
          command_data = buffer_data(file,i).split("\n").map {|s| s[2..-1] }
          do_drill(screen,data,command_data,i)
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

  def script_file
    return File.expand_path(File.dirname(__FILE__)+"/../../lessons/gtypist.typ")
  end

  def start
    Rtypist::Screen.new.with_screen do |screen|
      screen.banner("Loading " + File.basename(script_file))
      build_label_index(script_file)
      label = nil
      begin
        label = parse_file(screen,script_file,label)
      end while label
    end
  end
end
