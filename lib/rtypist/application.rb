require 'ncursesw'

class Rtypist::Application

  TOP = 0

  C_NORMAL = 1;
  C_BANNER = 2;
  C_PROG_NAME = 3;
  C_PROG_VERSION = 4;
  C_MENU_TITLE = 5;

  def initialize(options = {})
    @options = options
  end

  def add_rev str
     Ncurses.attron(Ncurses::A_REVERSE);
     Ncurses.addstr str;
     Ncurses.attroff(Ncurses::A_REVERSE);
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
    Ncurses.initscr
    begin
      Ncurses.clear
      Ncurses.refresh
      Ncurses.typeahead -1
      Ncurses.noecho
      Ncurses.curs_set 0
               
      Ncurses.raw
      banner("Loading " + File.basename(script_file))
      Ncurses.getch
    ensure
      Ncurses.curs_set 1
      Ncurses.endwin
    end
  end
end
