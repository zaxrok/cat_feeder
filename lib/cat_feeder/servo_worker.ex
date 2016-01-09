defmodule CatFeeder.ServoWorker do
  require Logger
  use Bitwise 
  use GenServer
  
  @mode1      0x00 # bit 4 is SLEEP 000X0000
  @mode2      0x01
  @prescale   0xFE

  @all_on_l   0xFA
  @all_on_h   0xFB
  @all_off_l  0xFC
  @all_off_h  0xFD

  @led0_on_l  0x06
  @led0_on_h  0x07
  @led0_off_l 0x08
  @led0_off_h 0x09

  @allcall 0x01
  @outdrv 0x04
  @swrst 0x06

  # Client

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: ServoSpinner)
  end

  # Server Callbacks

  def init(_opts) do
    Logger.debug "Initializing..."
    pid = Process.whereis( Servo )
    
    set_all_pwm(pid,0,0) 
    I2c.write(pid, <<@mode2, @outdrv>>) # external driver, see docs
    I2c.write(pid, <<@mode1, @allcall>>) # program all PCA9685's at once
    :timer.sleep 5 
    prescale(pid, 60) # set pwm to 60 Hz 

    {:ok, :nostate}
  end

  def handle_info(:bump, state) do
    pid = Process.whereis( Servo )
    bump(pid)
    {:noreply, state}
  end 

  # PCA9685 Software Reset (Section 7.6 on pg 28)
  def swrst do
    Logger.debug "PCA9685 Software Reset..."
    {:ok,pid}=I2c.start_link("i2c-1", 0x00)
    :timer.sleep 10
    I2c.write(pid,<<@swrst>>)
  end

  def prescale(pid,freq) do
    Logger.debug "Setting prescale to #{freq} Hz" 

    # pg 14 and solve for prescale or example on pg 25
    prescaleval = trunc(Float.round( 25000000.0 / 4096.0 / freq ) - 1 )
    Logger.debug "prescale value is #{prescaleval}"

    oldmode = I2c.write_read(pid, <<@mode1>>, 1)
    :timer.sleep 5
    I2c.write(pid, <<@mode1, 0x11>>) # set bit 4 (sleep) to allow setting prescale
    I2c.write(pid, <<@prescale, prescaleval>> )
    I2c.write(pid, <<@mode1, 0x01>> ) #un-set sleep bit
    :timer.sleep 5 # pg 14 it takes 500 us for the oscillator to be ready

    I2c.write(pid, <<@mode1>> <> oldmode ) # put back old mode

  end
 
  # spin one way
  def min(pid) do
    Logger.debug "min"
    set_pwm(pid, 0, 0, 0x0096)
  end
 
  # spin the other way  
  def max(pid) do
    Logger.debug "max"
    set_pwm(pid, 0, 0, 0x0258)
  end
 
  # stop 
  def mid(pid) do
    Logger.debug "mid"
    set_pwm(pid, 0, 0, 0)
  end

  # spins just a bit in one direction and stops
  def bump(pid) do
    Logger.debug "bump"
    min(pid)
    :timer.sleep 200
    mid(pid)
  end

  # The registers for each of the 16 channels are sequential
  # so the address can be calculated as an offset from the first one
  def set_pwm(pid, channel, on, off) do
    I2c.write(pid, <<@led0_on_l+4*channel, on &&& 0xFF>>)
    I2c.write(pid, <<@led0_on_h+4*channel, on >>> 8>>)
    I2c.write(pid, <<@led0_off_l+4*channel, off &&& 0xFF>>) 
    I2c.write(pid, <<@led0_off_h+4*channel, off >>> 8>>)
  end

  # The PCA9685 has special registers for setting ALL channels
  # (or 1/3 of them) to the same value. 
  def set_all_pwm(pid, on, off) do
    I2c.write(pid, <<@all_on_l, on &&& 0xFF>>)
    I2c.write(pid, <<@all_on_h, on >>> 8>>)
    I2c.write(pid, <<@all_off_l, off &&& 0xFF>>)
    I2c.write(pid, <<@all_off_h, off >>> 8>>)
  end
end
