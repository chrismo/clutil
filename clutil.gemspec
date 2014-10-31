# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'clutil'

  # Year, day of the year, release.
  # --
  # This was perhaps a creative way to do this, pre-SemVer,
  # and maybe I'll just go SemVer one day ... but not this day.
  s.version = Time.now.strftime('%Y.%j.0')

  s.authors = ['chrismo']
  s.description = 'a mish-mash of spare utility libs for Ruby.'
  s.email = ['chrismo@clabs.org']
  s.homepage = 'http://clabs.org/ruby.htm'
  s.licenses = ['MIT']
  s.summary = 'cLabs Ruby Utilities'

  s.files = Dir.glob('cl/**/*.rb')

  s.add_runtime_dependency 'rake'
end
