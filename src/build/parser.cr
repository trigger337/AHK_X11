require "../cmd/**"

module Build
	class ParsingException < Exception end

	# parse lines into fully instantiated ahk commands with their respective arguments
	# (includes syntax checks)
	class Parser
		@@cmd_class_by_name : Hash(String, Cmd::Base.class)
		@@cmd_class_by_name = Cmd::Base.all_subclasses
			.reduce({} of String => Cmd::Base.class) do |acc, cmd_class|
				acc[cmd_class.name] = cmd_class
				acc
			end

		getter cmds = [] of Cmd::Base
		getter hotkey_labels = [] of String
		getter comment_flag = ";"
		getter escape_char = '`'

		@block_comment = false

		def parse_into_cmds!(lines : Array(String))
			lines.each_with_index do |line, line_no|
				begin
					add_line line, line_no
				rescue e
					{% if ! flag?(:release) %}
						puts "[debug]", e.inspect_with_backtrace
					{% end %}
					raise Cmd::SyntaxException.new "Syntax Error in line #{line_no+1}: '#{e.message}'. Line content was: '#{line}'."
				end
			end
			raise Cmd::SyntaxException.new "Missing */" if @block_comment
		end

		def add_line(line, line_no)
			match = line
				.sub(/(^| |\t)#{@comment_flag}.*$/, "") # rm comments
				.match(/^\s*([^\s,]*)\s*,?(.*)$/).not_nil!
			first_word = match[1].downcase
			args = match[2]
			csv_args = [] of String

			return if first_word.empty?
			# Almost everything starts with a regular command, but there are
			# a few exceptions: if, assignments.
			cmd_class = @@cmd_class_by_name[first_word]?
			if first_word == "/*"
				@block_comment = true
			elsif first_word == "*/"
				raise "Unexpected */" if ! @block_comment
				@block_comment = false
			elsif @block_comment
				#
			elsif cmd_class
				if args.empty?
					csv_args = [] of String
				else
					csv_args = args.split(/(?<!#{@escape_char}),/, cmd_class.max_args + 1).map do |arg|
						arg.strip.gsub(/(?<!#{@escape_char})#{@escape_char},/, ",")
					end
				end
				if csv_args.size > cmd_class.max_args
					if cmd_class.multi_command
						# examples: if, ifequals, else, }, ifequals, ... can all have residue content.
						# split this line in two, add a new virtual line with the remainder.
						@cmds << cmd_class.new line_no, cmd_class.max_args > 0 ? csv_args[..cmd_class.max_args-1] : [] of String
						add_line csv_args[cmd_class.max_args], line_no
					else
						# attach the remainder again and pass as is to the arg
						# TODO also maybe only if allowed via flag? so that commands don't accidentally accept / combine too many arguments
						# TODO spacing can wrongly get lost / added here because of the .strip + add ", " which may not add up
						csv_args[cmd_class.max_args-1] += ", #{csv_args.pop}"
						@cmds << cmd_class.new line_no, csv_args
					end
				elsif csv_args.size < cmd_class.min_args
					raise "Minimum arguments required for '#{cmd_class.name}' is '#{cmd_class.min_args}', got '#{csv_args.size}'"
				else
					@cmds << cmd_class.new line_no, csv_args
				end
			elsif first_word == "if"
				split = args.split(/ |\n/, 3, remove_empty: true)
				case split[1]?
				when "="
					cmd_class = Cmd::IfEqual
				else
					raise "If condition '#{split[1]?}' is unknown"
				end
				csv_args = [split[0], split[2]? || ""]
				@cmds << cmd_class.new line_no, csv_args
			elsif first_word.ends_with?("::")
				raise "Hotkeys can not have arguments" if args.size > 0
				label = first_word[...-2]
				@cmds << Cmd::Label.new line_no, [label]
				@hotkey_labels << label
			elsif first_word.ends_with?(':')
				raise "Labels can not have arguments" if args.size > 0
				@cmds << Cmd::Label.new line_no, [first_word[...-1]]
			else
				split = args.split()
				if split[0]? == "="
					cmd_class = Cmd::SetEnv
					csv_args = [first_word, split[1]? || ""]
				else
					raise "Command '#{first_word}' not found"
				end
				@cmds << cmd_class.new line_no, csv_args
			end
		end
	end
end