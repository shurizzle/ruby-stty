#--
# Copyleft shura. [ shura1991@gmail.com ]
#
# This file is part of stty.
#
# stty is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# stty is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with stty. If not, see <http://www.gnu.org/licenses/>.
#++

require 'termios'

module STTY
  include Termios
  DEFAULT_CC = [3, 28, 127, 21, 4, 0, 1, 0, 17, 19, 26, 0, 18, 15, 23, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  def ispeed=(bauds)
    return unless bauds.is_a?(Integer)
    t = self.tcgetattr
    t.ispeed = bauds
    self.tcsetattr(TCSANOW, t)
    self
  end

  def ospeed=(bauds)
    return unless bauds.is_a?(Integer)
    t = self.tcgetattr
    t.ospeed = bauds
    self.tcsetattr(TCSANOW, t)
    self
  end

  def speed=(bauds)
    self.ispeed = bauds
    self.ospeed = bauds
  end


  {
    iflag: IFLAG_NAMES,
    oflag: OFLAG_NAMES,
    cflag: CFLAG_NAMES,
    lflag: LFLAG_NAMES
  }.each {|meth, syms|
    getter = Termios.instance_method(meth)
    setter = Termios.instance_method("#{meth}=")

    syms.each {|sym|
      val = self.const_get(sym)
      sym = sym.to_s.downcase

      if sym !~ /^(?!i).*\d+$/
        define_method("#{sym}=") {|bool|
          to = self.tcgetattr
          t = getter.bind(to)
          s = setter.bind(to)
          s.call(bool ? t.call | val : t.call & ~val)
          self.tcsetattr(TCSANOW, to)
          self
        }

        define_method("#{sym}?") {
          (getter.bind(self.tcgetattr).call & val) == val
        }

        define_method("no#{sym}") {|&blk|
          old = self.send("#{sym}?")
          self.send("#{sym}=", false)

          if blk
            return blk.call(self).tap {
              self.send("#{sym}=", old)
            }
          end

          nil
        }

        define_method(sym) {|&blk|
          old = self.send("#{sym}?")
          self.send("#{sym}=", true)

          if blk
            return blk.call(self).tap {
              self.send("#{sym}=", old)
            }
          end

          nil
        }
      else
        define_method(sym) {
          to = self.tcgetattr
          t = getter.bind(to)
          s = setter.bind(to)
          s.call(t.call | val)
          self.tcsetattr(TCSANOW, to)
          self
        }
      end
    }
  }

  CCINDEX.each {|i, n|
    n = n.to_s.downcase.sub(/^v/, '')

    define_method(n) {
      self.tcgetattr.cc[i]
    }

    define_method("#{n}=") {|v|
      t = self.tcgetattr
      t.cc[i] = v
      self.tcsetattr(TCSANOW, t)
      self
    }
  }

  def tabs
    self.tab0
  end

  def notabs
    self.tab3
  end

  def ek
    self.erase, self.kill = DEFAULT_CC[VERASE], DEFAULT_CC[VKILL]
  end

  def evenp
    self.parenb; self.noparodd; self.cs7
  end

  def noevenp
    self.noparenb; self.cs8
  end

  def lcase
    if block_given?
      return xcase { iuclc { olcuc {
        yield self
      } } }
    else
      self.xcase; self.iuclc; self.olcuc
    end

    nil
  end

  def nolcase
    if block_given?
      return noxcase { noiuclc { noolcuc {
        yield self
      } } }
    else
      self.noxcase; self.noiuclc; self.noolcuc
    end

    nil
  end

  def nolitout
    self.parenb; self.istrip; self.opost; self.cs7
    nil
  end

  def crt
    if block_given?
      return echoe { echoctl { echoke {
        yield self
      } } }
    else
      echoe; echoctl; echoke
    end

    nil
  end

  def dec
    if block_given?
      x = [self.intr, self.erase, self.kill]

      return echoe { echoctl { echoke { noixany {
        self.intr, self.erase, self.kill = 0x03, 0x7f, 0x16
        yield(self).tap {
          self.intr, self.erase, self.kill = x
        }
      } } } }
    else
      echoe; echoctl; echoke; noixany
      self.intr, self.erase, self.kill = 0x03, 0x7f, 0x16
    end

    nil
  end

  def oddp
    self.parenb; self.parodd; self.cs7
  end

  def nooddp
    self.noparenb; self.cs8
  end

  def pass8
    self.noparenb; self.noistrip; self.cs8
  end

  def nopass8
    self.noparenb; self.noistrip; self.cs7
  end

  def nl
    if block_given?
      return noicrnl { noonlcr {
        yield self
      } }
    else
      noicrnl; noonlcr
    end

    nil
  end

  def nonl
    if block_given?
      return icrnl { noinlcr { noigncr { onlcr { noocrnl { noonlret {
        yield self
      } } } } } }
    else
      icrnl; noinlcr; noigncr; onlcr; noocrnl; noonlret
    end

    nil
  end

  def crtkill?
    echoprt? and echoe?
  end

  def crtkill
    if block_given?
      return echoprt { echoe {
        yield self
      } }
    else
      echoprt; echoe
    end

    nil
  end

  def nocrtkill
    if block_given?
      return echoctl { echok {
        yield self
      } }
    else
      echoctl; echok
    end

    nil
  end

  def cbreak?
    !self.icanon?
  end

  def cbreak=(bool)
    self.icanon = !bool
  end

  def cbreak(&blk)
    noicanon(&blk)
  end

  def nocbreak(&blk)
    icanon(&blk)
  end

  def sane
    self.cread; self.noignbrk; self.brkint; self.noinlcr; self.igncr; self.icrnl
    self.noiutf8; self.noixoff; self.noiuclc; self.noixany; self.imaxbel; self.opost
    self.noolcuc; self.noocrnl; self.onlcr; self.noonocr; self.noonlret; self.noofill
    self.noofdel; self.nl0; self.cr0; self.tab0; self.bs0; self.vt0; self.ff0
    self.isig; self.icanon; self.iexten; self.echo; self.echoe; self.echok
    self.noechonl; self.nonoflsh; self.noxcase; self.notostop; self.noechoprt
    self.echoctl; self.echoke
    t = self.tcgetattr
    t.cc = DEFAULT_CC[0, NCCS]
    self.tcsetattr(TCSANOW, t)
    nil
  end

  def raw?
    %w{ignbrk brkint ignpar parmrk inpck istrip inlcr igncr icrnl ixon ixoff iuclc ixany imaxbel opost isig icanon xcase}.map {|sym|
      !self.send("#{sym}?")
    }.inject(:&) and self.min == 1 and self.time == 0
  end

  def raw=(bool)
    %w{ignbrk brkint ignpar parmrk inpck istrip inlcr igncr icrnl ixon ixoff iuclc ixany imaxbel opost isig icanon xcase}.each {|sym|
      self.send("#{sym}=", !bool)
    }

    if bool
      self.min = 1
      self.time = 0
    end

    self
  end

  def raw(&blk)
    if blk
      %w{ignbrk brkint ignpar parmrk inpck istrip inlcr igncr icrnl ixon ixoff iuclc ixany imaxbel opost isig icanon xcase}.inject(blk) {|block, sym|
        lambda {|*|
          self.send("no#{sym}", &block)
        }
      }.call
    else
      %w{ignbrk brkint ignpar parmrk inpck istrip inlcr igncr icrnl ixon ixoff iuclc ixany imaxbel opost isig icanon xcase}.each {|sym|
        self.send("no#{sym}")
      }
    end
  end

  def noraw(&blk)
    if blk
      %w{ignbrk brkint ignpar parmrk inpck istrip inlcr igncr icrnl ixon ixoff iuclc ixany imaxbel opost isig icanon xcase}.inject {|block, sym|
        lambda {
          self.send(sym, &block)
        }
      }.call
    else
      %w{ignbrk brkint ignpar parmrk inpck istrip inlcr igncr icrnl ixon ixoff iuclc ixany imaxbel opost isig icanon xcase}.each {|sym|
        self.send(sym)
      }
    end
  end

  def cooked?
    %w{ignbrk brkint ignpar parmrk inpck istrip inlcr igncr icrnl ixon ixoff iuclc ixany imaxbel opost isig icanon xcase}.map {|sym|
      self.send("#{sym}?")
    }.inject(:&)
  end

  def cooked=(bool)
    self.raw = !bool
  end

  def cooked(&blk)
    noraw(&blk)
  end

  def nocooked(&blk)
    raw(&blk)
  end

  def size
    data = [0, 0, 0, 0].pack('SSSS')

    if self.ioctl(TIOCGWINSZ, data) >= 0
      rows, cols, * = data.unpack('SSSS')
      [rows, cols]
    else
      [80, 80]
    end
  end

  def cols
    self.size[1]
  end
  alias columns cols

  def rows
    self.size[0]
  end

  def cols=(n)
    data = [self.rows, n, 0, 0].pack('SSSS')

    self.ioctl(TIOCSWINSZ, data) >= 0 ? true : false
  end
  alias columns= cols=

  def rows=(n)
    data = [n, self.cols, 0, 0].pack('SSSS')

    self.ioctl(TIOCSWINSZ, data) >= 0 ? true : false
  end

  %w{echoctl ctlecho echoe crterase echoke crtkill echoprt prterase ixany decctlq
    hupcl hup ixoff tandem evenp parity}.each_slice(2) {|args|
    o, a = args.map(&:to_sym)
    next unless (self.instance_method(o) rescue nil)

    eval("alias #{a} #{o}")

    next unless (self.instance_method("#{o}?") rescue nil)
    eval("alias #{a}? #{o}?")
    eval("alias #{a}= #{o}=")
    eval("alias no#{a} no#{o}")
  }
end
