require "./base"

# INCOMPAT: wrong labels for gosub/goto are only evaluated at runtime an result in thread exit.
# In win ahk, (only) when the label name is fixed and not computed, it's a build time error and program exit.
class Cmd::Gosub < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread)
		thread.gosub(thread.runner.str(@args[0]))
	end
end