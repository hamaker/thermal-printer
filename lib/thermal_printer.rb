require "thermal_printer/version"
require 'rubyserial'

class ThermalPrinter
  attr_reader :printer
  SERIAL_PORT = '/dev/ttyAMA0'
  BAUDRATE = 19200
  # TIMEOUT = 3

  ESC = 27
  GS  = 29

  def initialize(heat_time: 80, heat_interval: 2, heating_dots: 7, serialport: SERIAL_PORT)
    @printer = Serial.new(serialport, BAUDRATE)
    printer.write(ESC) # ESC - command
    printer.write(64.chr) # @   - initialize
    printer.write(ESC) # ESC - command
    printer.write(55.chr) # 7   - print settings
    printer.write(heating_dots.chr)  # Heating dots (20=balance of darkness vs no jams) default = 20
    printer.write(heat_time.chr) # heatTime Library default = 255 (max)
    printer.write(heat_interval.chr) # Heat interval (500 uS = slower, but darker) default = 250

    # Description of print density from page 23 of the manual:
    # DC2 # n Set printing density
    # Decimal: 18 35 n
    # D4..D0 of n is used to set the printing density. Density is 50% + 5% * n(D4-D0) printing density.
    # D7..D5 of n is used to set the printing break time. Break time is n(D7-D5)*250us.
    print_density = 15 # 120% (? can go higher, text is darker but fuzzy)
    print_break_time = 15 # 500 uS
    printer.write(18.chr)
    printer.write(35.chr)
    printer.write(((print_density << 4) | print_break_time).chr)
  end

  def offline
    write_decimal(ESC, 61, 0)
  end

  def online
    write_decimal(ESC, 61, 1)
  end

  def reset
    write_decimal(ESC, 64)
  end

  def print_text(message)
    printer.write(message)
  end

  def linefeed
    write_decimal(10)
  end

  def justify(position=:left)
    justification_map = {
      left: 0,
      center: 1,
      right: 2
    }
    write_decimal(ESC, 97, justification_map[position])
  end

  def bold_on
    write_decimal(ESC, 69, 1)
  end

  def bold_off
    write_decimal(ESC, 69, 0)
  end

  def bold
    bold_on
    yield
    bold_off
  end

  def double_width_on
    write_decimal(ESC, 14)
  end

  def double_width_off
    write_decimal(ESC, 20)
  end

  def double_width
    double_width_on
    yield
    double_width_off
  end

  def updown_on
    write_decimal(ESC, 123, 1)
  end

  def updown_off
    write_decimal(ESC, 123, 0)
  end

  def inverse_on
    write_decimal(GS, 66, 1)
  end

  def ineverse_off
    write_decimal(ESC, 66, 0)
  end

  private

  def write_decimal(*args)
    args.each { |c| printer.write c.chr }
  end

  def black_threshold
    48
  end

  def alpha_threshold
    127
  end
end
