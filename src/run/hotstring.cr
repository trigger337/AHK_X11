module Run
	alias HotstringAbbrevKeysyms = StaticArray(Char, 30)

	class Hotstring
		property runner : Run::Runner?
		getter abbrev : String
		getter abbrev_keysyms : HotstringAbbrevKeysyms
		getter abbrev_size : UInt8
		property label : String
		property cmd : Cmd::Base?
		property immediate = false
		def initialize(@label, @abbrev)
			@abbrev_size = @abbrev.size.to_u8
			@abbrev_keysyms = HotstringAbbrevKeysyms.new do |i|
				if i >= @abbrev_size
					'0'
				else
					@abbrev[i]
				end
			end
		end
		def keysyms_equal?(other_keysyms : HotstringAbbrevKeysyms, other_size : UInt8)
			return false if other_size != @abbrev_size
			@abbrev_keysyms.each_with_index do |k, i|
				break if i >= @abbrev_size
				return false if k != other_keysyms[i]
			end
			true
		end
		def trigger
			runner = @runner.not_nil!
			
			runner.pause_x11
			(@abbrev_size + (@immediate ? 0 : 1)).times do a = 1
				runner.x_do.keys "BackSpace"
			end
			runner.resume_x11
			
			runner.add_thread @cmd.not_nil!, 0 # @priority
		end
	end
end