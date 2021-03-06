require "thermal_printer/version"
require 'rubyserial'

class ThermalPrinter
  attr_reader :printer
  SERIAL_PORT = '/dev/ttyAMA0'
  BAUDRATE = 19200
  PRINT_DENSITY= 15
  PRINT_BREAK_TIME = 15
  # TIMEOUT = 3

  ESC = 27
  GS  = 29

  def initialize(heat_time: 80, heat_interval: 2, heating_dots: 7, serialport: SERIAL_PORT)
    @printer = Serial.new(serialport, BAUDRATE)
    write_decimal(ESC,64) # initialize
    write_decimal(ESC,55,heating_dots,heat_time,heat_interval) # print settings

    # Description of print density from page 23 of the manual:
    # DC2 # n Set printing density
    # Decimal: 18 35 n
    # D4..D0 of n is used to set the printing density. Density is 50% + 5% * n(D4-D0) printing density.
    # D7..D5 of n is used to set the printing break time. Break time is n(D7-D5)*250us.
    print_density = ((PRINT_DENSITY << 4) | PRINT_BREAK_TIME)
    write_decimal(18,35,print_density)
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
