Gem::Specification.new {|g|
    g.name          = 'stty'
    g.version       = '0.0.2'
    g.author        = 'shura'
    g.email         = 'shura1991@gmail.com'
    g.homepage      = 'http://github.com/shurizzle/ruby-stty'
    g.platform      = Gem::Platform::RUBY
    g.description   = 'lib to set and get terminal line settings'
    g.summary       = g.description.dup
    g.files         = Dir.glob('lib/**/*')
    g.require_path  = 'lib'
    g.executables   = [ ]
    g.has_rdoc      = true

    g.add_dependency('ruby-termios')
}
