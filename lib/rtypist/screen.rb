require 'ncursesw'

module Rtypist
class Screen
  
  C_NORMAL = 1
  C_BANNER = 2
  C_PROG_NAME = 3
  C_PROG_VERSION = 4
  C_MENU_TITLE = 5

  TOP = 0
   
  def initialize
     @ncurses = Ncurses.initscr
  end
  
  def with_screen
    begin
        Ncurses.clear
        Ncurses.refresh
        Ncurses.typeahead -1
        Ncurses.noecho
        Ncurses.curs_set 0
        Ncurses.keypad(Ncurses.stdscr,true)         
        Ncurses.raw
          Ncurses.start_color
          Ncurses.init_pair(C_NORMAL, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK);
          Ncurses.init_pair(C_BANNER, Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK);
          Ncurses.init_pair(C_PROG_NAME, Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK);
          Ncurses.init_pair(C_PROG_VERSION, Ncurses::COLOR_CYAN, Ncurses::COLOR_RED);
          Ncurses.init_pair(C_MENU_TITLE, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK);

        yield self
        Ncurses.getch
      ensure
        Ncurses.curs_set 1
        Ncurses.endwin
      end
   end
  
   def key_up
     Ncurses::KEY_UP
   end
  
   def key_down
     Ncurses::KEY_DOWN
   end
  
   def key_enter
     Ncurses::KEY_ENTER
   end
   
   def key_cancel
     Ncurses::KEY_CANCEL
   end
  
   def key_backspace
     Ncurses::KEY_BACKSPACE
   end
  
   def lines
     Ncurses.LINES
   end
   
   def cols
     Ncurses.COLS
   end
  
   def getch
     Ncurses.getch
   end
  
   def addch(rc)
     Ncurses.addch(rc)
   end
  
   def ungetch(rc)
     Ncurses.ungetch(rc)
   end
  
   def move_to_line(linenum)
     Ncurses.move(linenum,0)
   end
  
   def addstrat(line,col,str)
     Ncurses.move(line,col)
     Ncurses.addstr(str)
   end
  
   def add_mode(text)
     Ncurses.move(lines - 1, 0)
     Ncurses.clrtoeol
     Ncurses.move(lines - 1, cols - text.length - 2)
     add_rev(" #{text} ")
   end
  
   def getch_fl(cursor_char)
     y,x = Ncurses.getcury(@ncurses), Ncurses.getcurx(@ncurses)
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
  
   def write_at(max_width, text_start_y,text_start_x,text,reverse = false)
     if (reverse)
       Ncurses.wattron(@ncurses, Ncurses::A_REVERSE)
       Ncurses.mvaddstr(text_start_y,text_start_x,text)
       Ncurses.addstr(' ' * (max_width - text.length))
       Ncurses.wattroff(@ncurses, Ncurses::A_REVERSE)
     else
       Ncurses.wattroff(@ncurses, Ncurses::A_REVERSE)
       Ncurses.mvaddstr(text_start_y,text_start_x,text)
       Ncurses.addstr(' ' * (max_width - text.length))
     end
  end
  
  def add_lines(lines,start_line,step=1)
    line = start_line
    clear_from_line(start_line)
    lines.each_with_index do |l,i|
      addstrat(line+(i*step),0,l)
    end
  end
  
   def bottom_line(line)
     Ncurses.move(Ncurses.LINES - 1, 0)
     Ncurses.clrtoeol
     Ncurses.mvaddstr(Ncurses.LINES - 1, 0, line)
   end
  
   def add_title(title)
     Ncurses.wattron(@ncurses, Ncurses::A_BOLD)
     Ncurses.attron(Ncurses.COLOR_PAIR(C_MENU_TITLE));
     Ncurses.mvaddstr(2,(80 - title.length)/ 2, title)
     Ncurses.attron(Ncurses.COLOR_PAIR(C_NORMAL));
     Ncurses.wattroff(@ncurses, Ncurses::A_BOLD)
   end
  
   def clear_from_line(line)
     Ncurses.move(line,0)
     Ncurses.clrtobot
   end
  
   def banner(text,brand = "rtypist", version =  Rtypist::VERSION)
     text = text.strip
     brand = " #{brand} "
     cols = Ncurses.COLS
     brand_pos = cols - brand.length - version.length - 4
     text_pos = ((cols-brand.length) > text.length) ? (cols - brand.length - text.length) / 2 : 0
     Ncurses.move(0, 0)
     Ncurses.attron(Ncurses.COLOR_PAIR(C_BANNER))    
     cols.times {  add_rev ' ' }
     Ncurses.move(TOP, text_pos);
     add_rev(text)
     Ncurses.move(TOP, brand_pos)
     Ncurses.attron(Ncurses.COLOR_PAIR(C_PROG_NAME));
     add_rev(" #{brand} ");
     Ncurses.attron(Ncurses.COLOR_PAIR(C_PROG_VERSION));
     add_rev(" #{version} ");
     Ncurses.refresh();
     Ncurses.attron(Ncurses.COLOR_PAIR(C_NORMAL));
   end
  
   def add_rev str
      Ncurses.attron(Ncurses::A_REVERSE);
      Ncurses.addstr str;
      Ncurses.attroff(Ncurses::A_REVERSE);
   end
   
   def results_box(messages)
     line = Ncurses.LINES - messages.length - 2
     width = messages.map {|m| m.length }.max + 2
     
     messages.each do |message|
       Ncurses.move(line,Ncurses.COLS - width)
       add_rev(" #{message} ")
       line += 1
     end
  end
   
end
end