#==============================================================================
#    Pear AnimCEL
#    Version: 1.0.0
#    Author: pearcoding
#    Date: 20.08.2015
#==============================================================================
#
# Animation control and execution language
#
# Reminder: Source tree optimization is not included.
#						The benefits of optimization compared to the amount of work
#						is not worth it, so I decided to not implement it.
#

$imported = {} if $imported.nil?
$imported["Pear_AnimCEL"] = 1.0

module Pear
  module AnimCEL
		#--------------------------------------------------------------------------
		# Core
		#--------------------------------------------------------------------------
		TEST = true
			
		#--------------------------------------------------------------------------
		# Lexer
		#--------------------------------------------------------------------------
		
		#==========================================================================
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		# !!!        Everything after this is not for casual editing.          !!!
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#==========================================================================
		
		alias error printf
		public :error
		alias debug printf
		public :debug
		
		#==========================================================================
		# ■ Token
		# Handles symbolic tokens
		#==========================================================================
		class Token
			attr_accessor :symbol
			attr_accessor :data
			
			def initialize(sym, data=nil)
				@symbol = sym
				@data 	= data
			end
			
			def hasData?
				return data != nil
			end
		end
		
		#==========================================================================
		# ■ InterpreterNode
		# Source Tree representation for the interpreter/VM
		#==========================================================================
		class InterpreterNode
			attr_accessor :children
			attr_accessor :operation
			
			def initialize(op, *children)
				@operation 	= op
				@children		= children
			end
			
			def count
				return @children.size
			end
		end
		
		#==========================================================================
		# ■ Lexer
		# Reads string and splits it into tokens
		#==========================================================================
		class Lexer
			def initialize(str)
				@str = str
				@index = 0
			end
			
			# Work functions
			def index
				return @index
			end
			
			def inc_index
				@index = @index + 1 unless end?
			end
			
			def current_char
				return @str[index]
			end
			
			def end?
				return index >= @str.size
			end
			
			# Common errors
			def error_end_of_stream
				error("AnimCEL: Unexpected end of stream\n")
				return Token.new(:T_ERROR)
			end
			
			def error_unexpected(c, expected)
				error("AnimCEL: Unexpected character '%c' expected '%c'", c, expected)
				return Token.new(:T_ERROR)
			end
			
			# Lexer functions
			def next_token				
				return Token.new(:T_END) if end?
				
				###### Translation Unit Start
				if current_char == '['
					inc_index
					return error_end_of_stream if end?
					
					if current_char == '@'
						inc_index
						return Token.new(:T_TU_START)
					else
						return error_unexpected(current_char, '@')
					end
				###### Open paranthese
				elsif current_char == '(' 
					inc_index
					return Token.new(:T_OPEN_PARANTHESE)
				###### Close paranthese
				elsif current_char == ')' 
					inc_index
					return Token.new(:T_CLOSE_PARANTHESE)
				###### Add
				elsif current_char == '+' 
					inc_index
					return Token.new(:T_ADD)
				###### Sub
				elsif current_char == '-' 
					inc_index
					return Token.new(:T_SUB)
				###### Mul
				elsif current_char == '*' 
					inc_index
					return Token.new(:T_MUL)
				###### Div
				elsif current_char == '/' 
					inc_index
					return Token.new(:T_DIV)
				###### Mod
				elsif current_char == '%' 
					inc_index
					return Token.new(:T_MOD)
				###### Attention Mark
				elsif current_char == '!' 
					inc_index
					return error_end_of_stream if end?
					
					if current_char == '='
						inc_index
						return Token.new(:T_NON_EQUAL)
					else
						return Token.new(:T_ATTENTION_MARK)
					end
				###### Logical Or
				elsif current_char == '|' 
					inc_index
					return error_end_of_stream if end?
					
					if current_char == '|'
						inc_index
						return Token.new(:T_LOG_OR)
					else
						return error_unexpected(current_char, '|')
					end
				###### Logical And
				elsif current_char == '&' 
					inc_index
					return error_end_of_stream if end?
					
					if current_char == '&'
						inc_index
						return Token.new(:T_LOG_AND)
					else
						return error_unexpected(current_char, '&')
					end
				###### Equal
				elsif current_char == '=' 
					inc_index
					return error_end_of_stream if end?
					
					if current_char == '='
						inc_index
						return Token.new(:T_EQUAL)
					else
						return error_unexpected(current_char, '|')
					end
				###### Less
				elsif current_char == '<' 
					inc_index
					return error_end_of_stream if end?
					
					if current_char == '='
						inc_index
						return Token.new(:T_EQUAL_LESS)
					else
						return Token.new(:T_LESS)
					end
				###### Greater
				elsif current_char == '>' 
					inc_index
					return error_end_of_stream if end?
					
					if current_char == '='
						inc_index
						return Token.new(:T_EQUAL_GREATER)
					else
						return Token.new(:T_GREATER)
					end
				###### Switch Variables
				elsif current_char == '$' 
					inc_index
					return error_end_of_stream if end?
					
					ind = ''
					while number?(current_char)
						ind += current_char
						inc_index
						return error_end_of_stream if end?
					end
						
					if ind.empty?
						error("AnimCEL: Invalid Variable[Switch] index")
						return Token.new(:T_ERROR)
					else
						#inc_index # Not needed due to the while loop
						return Token.new(:T_SWITCH, ind.to_i)
					end
				###### Global Variables
				elsif current_char == '@'				
					inc_index
					return error_end_of_stream if end?
					
					if current_char == ']'
						inc_index
						return Token.new(:T_TU_END)
					else
						ind = ''
						while number?(current_char)
							ind += current_char
							inc_index
							return error_end_of_stream if end?
						end
						
						if ind.empty?
							error("AnimCEL: Invalid Variable[Global] index")
							return Token.new(:T_ERROR)
						else
							#inc_index # Not needed due to the while loop
							return Token.new(:T_GLOBAL_VAR, ind.to_i)
						end
					end
				###### Local Variables
				elsif current_char == '#'
					inc_index
					return error_end_of_stream if end?
					
					ind = nil
					while alpha?(current_char)
						ind += current_char
						inc_index
						return error_end_of_stream if end?
					end
						
					if ind.empty?
						error("AnimCEL: Invalid Variable[Local] index")
						return Token.new(:T_ERROR)
					else
						#inc_index # Not needed due to the while loop
						return Token.new(:T_LOCAL_VAR, ind.to_s)
					end
				###### String
				elsif current_char == "'"
					inc_index
					return error_end_of_stream if end?
					
					tmpStr = ''
					slash = false
					while true
						if current_char == "\\"
							slash = true
						elsif slash || current_char != "'"
							tmpStr += "\\" if slash && current_char != "'"
							slash = false
							tmpStr += current_char
						else
							break
						end
						
						inc_index
						return error_end_of_stream if end?
					end
					
					inc_index
					return Token.new(:T_STRING, tmpStr)
				###### Function
				elsif current_char == '"'
					inc_index
					return error_end_of_stream if end?
					
					tmpStr = ''
					slash = false
					while true
						if current_char == "\\"
							slash = true
						elsif slash || current_char != '"'
							tmpStr += "\\" if slash && current_char != '"'
							slash = false
							tmpStr += current_char
						else
							break
						end
						
						inc_index
						return error_end_of_stream if end?
					end
					
					inc_index
					return Token.new(:T_FUNCTION, tmpStr)
				###### Identifiers
				elsif alpha?(current_char)
					tmpStr = ''
					containsAscii = false
					while alpha?(current_char)
						tmpStr += current_char
						
						if ascii?(current_char)
							containsAscii = true
						end
						
						inc_index
						return error_end_of_stream if end?
					end
					
					if containsAscii
						case tmpStr
						# Direction
						when 'up'
							return Token.new(:T_DIRECTION, :UP)
						when 'down'
							return Token.new(:T_DIRECTION, :DOWN)
						when 'left'
							return Token.new(:T_DIRECTION, :LEFT)
						when 'right'
							return Token.new(:T_DIRECTION, :RIGHT)
						# Boolean
						when 'true'
							return Token.new(:T_BOOL, true)
						when 'false'
							return Token.new(:T_BOOL, false)
						# Operations
						when 'set'
							return Token.new(:T_SET)
						when 'set_if'
							return Token.new(:T_SET_IF)
						when 'move'
							return Token.new(:T_MOVE)
						when 'if'
							return Token.new(:T_IF)
						when 'goto'
							return Token.new(:T_GOTO)
						when 'wait'
							return Token.new(:T_WAIT)
						when 'call'
							return Token.new(:T_CALL)
						when 'add'
							return Token.new(:T_ADD)
						when 'put'
							return Token.new(:T_PUT)
						when 'movie'
							return Token.new(:T_MOVIE)
						else
							return Token.new(:T_IDENTIFIER, tmpStr)
						end
					else
						#inc_index # Not needed due to the while loop
						return Token.new(:T_NUMBER, tmpStr.to_i)
					end
				###### Whitespaces
				elsif whitespace?(current_char)
					inc_index
					return next_token
				###### Ignore everything else :)
				else
					debug("AnimCEL: Unknown character %s\n", current_char)
					inc_index
					return next_token
				end
			end
			
			def lookup_token
				tmpIndex = @index
				t = next_token
				@index = tmpIndex
				return t
			end
			
			# Utility functions
			def whitespace?(c)
				return 	c == ' ' || c == '\r' || c == '\n' || c == '\t'
			end
			
			def ascii?(c)
				return 	c == 'A' ||  c == 'B' || c == 'C' || c == 'D' || c == 'E' ||
								c == 'F' ||  c == 'G' || c == 'H' || c == 'I' || c == 'J' ||
								c == 'K' ||  c == 'L' || c == 'M' || c == 'N' || c == 'O' ||
								c == 'P' ||  c == 'Q' || c == 'R' || c == 'S' || c == 'T' ||
								c == 'U' ||  c == 'V' || c == 'W' || c == 'X' || c == 'Y' ||
								c == 'Z' ||  c == 'a' || c == 'b' || c == 'c' || c == 'd' ||
								c == 'e' ||  c == 'f' || c == 'g' || c == 'h' || c == 'i' ||
								c == 'j' ||  c == 'k' || c == 'l' || c == 'm' || c == 'n' ||
								c == 'o' ||  c == 'p' || c == 'q' || c == 'r' || c == 's' ||
								c == 't' ||  c == 'u' || c == 'v' || c == 'w' || c == 'x' ||
								c == 'y' ||  c == 'z' || c == '_'
			end
			
			def numberWithoutZero?(c)
				return 	c == '1' || c == '2' || c == '3' || c == '4' || c == '5' ||
								c == '6' || c == '7' || c == '8' || c == '9'
			end
			
			def number?(c)
				return 	c == '0' || numberWithoutZero?(c)
			end
			
			def alpha?(c)
				return number?(c) || ascii?(c)
			end
		end # Lexer
		
		#==========================================================================
		# ■ Parser
		# Constructs a node representation from token stream (Lexer)
		#==========================================================================
		class Parser
			def initialize(str)
				@lexer = Lexer.new(str)
			end
			
			def match(token)
				t = @lexer.next_token
				
				if t.symbol != token
					error("AnimCEL: Unexpected symbol '%s' expected '%s'",
						t.symbol.to_s, token.to_s)
					return nil
				else
					return t
				end
			end
			
			def lookahead?(token)
				t = @lexer.lookup_token
				return t.symbol == token
			end
			
			def parse
				return nd_translation_unit
			end
			
			###### Internal statements:
			def nd_translation_unit
				return nil unless match(:T_TU_START)
				index = match(:T_NUMBER)
				return nil unless index
				stmnt = nd_statement
				return nil unless stmnt
				return nil unless match(:T_TU_END)
				return InterpreterNode.new(:N_TU, index.data, stmnt)
			end
			
			def nd_statement
				return nd_set_stmnt if lookahead?(:T_SET)
				return nd_set_if_stmnt if lookahead?(:T_SET_IF)
				return nd_move_stmnt if lookahead?(:T_MOVE)
				return nd_if_stmnt if lookahead?(:T_IF)
				return nd_goto_stmnt if lookahead?(:T_GOTO)
				return nd_wait_stmnt if lookahead?(:T_WAIT)
				return nd_call_stmnt if lookahead?(:T_CALL)
				return nd_add_stmnt if lookahead?(:T_ADD)
				return nd_put_stmnt if lookahead?(:T_PUT)
				return nd_movie_stmnt if lookahead?(:T_MOVIE)
			end
			
			def nd_set_stmnt
				return nil unless match(:T_SET)
				p1 = nd_int_expr
				return nil unless p1
				p2 = nd_int_expr
				return nil unless p2
				return InterpreterNode.new(:N_ST_SET, p1, p2)
			end
			
			def nd_set_if_stmnt
				return nil unless match(:T_SET_IF)
				p1 = nd_int_expr
				return nil unless p1
				p2 = nd_int_expr
				return nil unless p2
				cond = nd_condition
				return nil unless cond
				return InterpreterNode.new(:N_ST_SET_IF, p1, p2, cond)
			end
			
			def nd_move_stmnt
				return nil unless match(:T_MOVE)
				dir = match(:T_DIRECTION)
				return nil unless dir
				p1 = nd_int_expr
				return nil unless p1
				p2 = nd_int_expr
				return nil unless p2
				return InterpreterNode.new(:N_ST_MOVE, dir.data, p1, p2)
			end
			
			def nd_if_stmnt
				return nil unless match(:T_IF)
				cond = nd_condition
				return nil unless cond
				true_c = nd_int_expr
				return nil unless true_c
				false_c = nd_int_expr
				return nil unless false_c
				return InterpreterNode.new(:N_ST_IF, cond, true_c, false_c)
			end
			
			def nd_goto_stmnt
				return nil unless match(:T_GOTO)
				p1 = nd_int_expr
				return nil unless p1
				return InterpreterNode.new(:N_ST_GOTO, p1)
			end
			
			def nd_wait_stmnt
				return nil unless match(:T_WAIT)
				p1 = nd_int_expr
				return nil unless p1
				return InterpreterNode.new(:N_ST_WAIT, p1)
			end
			
			def nd_call_stmnt
				return nil unless match(:T_CALL)
				f = match(:T_STRING)
				return nil unless f
				return InterpreterNode.new(:N_ST_CALL, f.data)
			end
			
			def nd_add_stmnt
				return nil unless match(:T_ADD)
				v = nd_int_var
				return nil unless v
				p1 = nd_int_expr
				return nil unless p1
				return InterpreterNode.new(:N_ST_ADD, v, p1)
			end
			
			def nd_put_stmnt
				return nil unless match(:T_PUT)
				if lookahead?(:T_SWITCH)
					s = match(:T_SWITCH)
					return nil unless s
					cond = nd_condition
					return nil unless cond
					return InterpreterNode.new(:N_ST_PUT, s.data, cond, true)
				else
					v = nd_int_var
					return nil unless v
					p1 = nd_int_expr
					return nil unless p1
					return InterpreterNode.new(:N_ST_PUT, v, p1, false)
				end
			end
			
			def nd_movie_stmnt
				return nil unless match(:T_MOVIE)
				str = match(:T_STRING)
				return nil unless str
				return InterpreterNode.new(:N_ST_MOVIE, str.data)
			end
			
			###### Internal expressions
			# FIXME: Is the order of nd_**next**_expr and nd_**current**_expr right?
			
			def nd_log_or_expr
				p1 = nd_log_and_expr
				return nil unless p1
				if lookahead?(:T_LOG_OR)
					match(:T_LOG_OR)
					p2 = nd_log_or_expr
					return nil unless p2
					return InterpreterNode.new(:N_LOG_OR, p1, p2)
				else
					return p1
				end
			end
			
			def nd_log_and_expr
				p1 = nd_equal_expr
				return nil unless p1
				if lookahead?(:T_LOG_AND)
					match(:T_LOG_AND)
					p2 = nd_log_and_expr
					return nil unless p2
					return InterpreterNode.new(:N_LOG_AND, p1, p2)
				else
					return p1
				end
			end
			
			def nd_equal_expr
				p1 = nd_rel_expr
				return nil unless p1
				if lookahead?(:T_EQUAL)
					match(:T_EQUAL)
					p2 = nd_equal_expr
					return nil unless p2
					return InterpreterNode.new(:N_EQUAL, p1, p2, true)
				elsif lookahead?(:T_NON_EQUAL)
					match(:T_NON_EQUAL)
					p2 = nd_equal_expr
					return nil unless p2
					return InterpreterNode.new(:N_EQUAL, p1, p2, false)
				else
					return p1
				end
			end
			
			def nd_rel_expr
				p1 = nd_add_expr
				return nil unless p1
				if lookahead?(:T_LESS)
					match(:T_LESS)
					p2 = nd_rel_expr
					return nil unless p2
					return InterpreterNode.new(:N_REL, p1, p2, :LESS)
				elsif lookahead?(:T_EQUAL_LESS)
					match(:T_EQUAL_LESS)
					p2 = nd_rel_expr
					return nil unless p2
					return InterpreterNode.new(:N_REL, p1, p2, :EQUAL_LESS)
				elsif lookahead?(:T_GREATER)
					match(:T_GREATER)
					p2 = nd_rel_expr
					return nil unless p2
					return InterpreterNode.new(:N_REL, p1, p2, :GREATER)
				elsif lookahead?(:T_EQUAL_GREATER)
					match(:T_EQUAL_GREATER)
					p2 = nd_rel_expr
					return nil unless p2
					return InterpreterNode.new(:N_REL, p1, p2, :EQUAL_GREATER)
				else
					return p1
				end
			end
			
			def nd_add_expr
				p1 = nd_mul_expr
				return nil unless p1
				if lookahead?(:T_ADD)
					match(:T_ADD)
					p2 = nd_add_expr
					return nil unless p2
					return InterpreterNode.new(:N_ADD, p1, p2, true)
				elsif lookahead?(:T_SUB)
					match(:T_SUB)
					p2 = nd_add_expr
					return nil unless p2
					return InterpreterNode.new(:N_ADD, p1, p2, false)
				else
					return p1
				end
			end
			
			def nd_mul_expr
				p1 = nd_unary_expr
				return nil unless p1
				if lookahead?(:T_MUL)
					match(:T_MUL)
					p2 = nd_mul_expr
					return nil unless p2
					return InterpreterNode.new(:N_MUL, p1, p2, :MUL)
				elsif lookahead?(:T_DIV)
					match(:T_DIV)
					p2 = nd_mul_expr
					return nil unless p2
					return InterpreterNode.new(:N_MUL, p1, p2, :DIV)
				elsif lookahead?(:T_MOD)
					match(:T_MOD)
					p2 = nd_mul_expr
					return nil unless p2
					return InterpreterNode.new(:N_MUL, p1, p2, :MOD)
				else
					return p1
				end
			end
			
			def nd_unary_expr
				if lookahead?(:T_ADD)
					match(:T_ADD)
					p2 = nd_literal
					return nil unless p2
					return InterpreterNode.new(:N_UNARY, p1, :ADD)#No changes... could ignore it :D
				elsif lookahead?(:T_SUB)
					match(:T_SUB)
					p2 = nd_literal
					return nil unless p2
					return InterpreterNode.new(:N_UNARY, p1, :SUB)
				elsif lookahead?(:T_ATTENTION_MARK)
					match(:T_ATTENTION_MARK)
					p2 = nd_literal
					return nil unless p2
					return InterpreterNode.new(:N_UNARY, p1, :NEG)
				else
					return nd_literal
				end
			end
			
			def nd_literal
				if lookahead?(:T_OPEN_PARANTHESE)
					match(:T_OPEN_PARANTHESE)
					p = nd_expr
					return nil unless p
					match(:T_CLOSE_PARANTHESE)
					return p
				elsif lookahead?(:T_NUMBER)
					n = match(:T_NUMBER)
					return nil unless n
					return InterpreterNode.new(:N_LITERAL, n.data, :NUMBER)
				elsif lookahead?(:T_BOOL)
					b = match(:T_BOOL)
					return nil unless b
					return InterpreterNode.new(:N_LITERAL, b.data, :BOOL)
				elsif lookahead?(:T_FUNCTION)
					f = match(:T_FUNCTION)
					return nil unless f
					return InterpreterNode.new(:N_LITERAL, f.data, :FUNCTION)
				elsif lookahead?(:T_SWITCH)
					s = match(:T_SWITCH)
					return nil unless s
					return InterpreterNode.new(:N_LITERAL, s.data, :SWITCH)
				elsif lookahead?(:T_GLOBAL_VAR)
					v = match(:T_GLOBAL_VAR)
					return nil unless v
					return InterpreterNode.new(:N_LITERAL, v.data, :GLOBAL_VAR)
				elsif lookahead?(:T_LOCAL_VAR)
					v = match(:T_LOCAL_VAR)
					return nil unless v
					return InterpreterNode.new(:N_LITERAL, v.data, :LOCAL_VAR)
				else
					error("AnimCEL: Unexpected symbol '%s' expected a literal",
						t.symbol.to_s)
					return nil
				end
			end
			
			alias nd_expr nd_log_or_expr 			# Highest expression
			alias nd_condition nd_log_or_expr # Bool bounded expression (can be non-bool)
			alias nd_int_expr nd_add_expr 		# Non bool expressions
			
			def nd_int_var
				if lookahead?(:T_GLOBAL_VAR)
					v = match(:T_GLOBAL_VAR)
					return nil unless v
					return InterpreterNode.new(:N_VAR, v.data, :GLOBAL_VAR)
				elsif lookahead?(:T_LOCAL_VAR)
					v = match(:T_LOCAL_VAR)
					return nil unless v
					return InterpreterNode.new(:N_VAR, v.data, :LOCAL_VAR)
				else
					error("AnimCEL: Unexpected symbol '%s' expected a variable identifier",
						t.symbol.to_s)
					return nil
				end
			end
			
		end # Parser
		
		#==========================================================================
		# ■ VM
		# The core processor of the AnimCEL language
		# - You are free to implement your own virtual machine :D
		#==========================================================================
		class VM
			attr_reader 	:last_statement
			attr_accessor :variables
			
			def initialize
				@statements = {}
				@min_index = nil
				@max_index = 0
				@cur_index = nil
				@last_statement = nil
				@actor = nil
				@variables = {}
				@wait_count = 0
			end
			
			def add(str)
				parser = Parser.new(str)
				n = parser.parse
				if n && n.operation == :N_TU
					ind = n.children[0]
					@statements[ind] = n.children[1]
					
					if @min_index == nil || @min_index > ind 
						@min_index = ind
					end
					
					if @max_index < ind
						@max_index = ind
					end
					
					p @statements
				else
					print("Couldn't add statement to table.")
				end
			end
			
			def start(actor)
				start_from(actor, @min_index)
			end
			
			def start_from(actor, index)
				return unless @statements.include?(index)
				@cur_index = index
				@actor = actor
			end
			
			def stop
				@cur_index = nil
			end
			
			def step
				return if @cur_index == nil
				
				if @wait_count > 0
					@wait_count -= 1
					handle_on_wait
					return
				end
				
				if @statements.include?(@cur_index)
					@last_statement = @statements[@cur_index]
					exec_statement(@last_statement)
				else
					@cur_index += 1 until @statements.include?(@cur_index) ||
									@cur_index > @max_index					
					
					if @cur_index > @max_index
						@cur_index = nil # Stop execution
					end
				end	
			end
			
			#### Callbacks
			# Can be customized
			def handle_set(act, i1, i2)
				#TODO
				@cur_index += 1
			end
			
			def handle_set_if(act, i1, i2, cond)
				if cond
					#TODO
				end
				
				@cur_index += 1
			end
			
			def handle_move(act, dir, i1, i2)
				#TODO
				@cur_index += 1
			end
			
			def handle_if(act, cond, i1, i2)
				if cond
					if @statements.include?(i1)
						@cur_index = i1
					else
						@cur_index = nil # Stop execution
					end
				else
					if @statements.include?(i2)
						@cur_index = i2
					else
						@cur_index = nil # Stop execution
					end
				end
			end
			
			def handle_goto(act, i1)
				if @statements.include?(i1)
					@cur_index = i1
				else
					@cur_index = nil # Stop execution
				end
			end
			
			def handle_wait(act, i1)
				@wait_count = i1
				@cur_index += 1
			end
			
			def handle_call(act, str)
				eval(str)
				@cur_index += 1
			end
			
			def handle_add_global(act, var, i1)
				@game_variables[var] += i1
				@cur_index += 1
			end
			
			def handle_add_local(act, var, i1)
				@variables[var] += i1
				@cur_index += 1
			end
			
			def handle_put_switch(act, var, b1)
				$game_switches[var] = b1
				@cur_index += 1
			end
			
			def handle_put_global(act, var, i1)
				$game_variables[var] = i1
				@cur_index += 1
			end
			
			def handle_put_local(act, var, i1)
				@variables[var] = i1
				@cur_index += 1
			end
			
			def handle_movie(act, str)
				#TODO
				@cur_index += 1
			end
			
			def handle_on_wait
			end
			
			#### Internal functions
			def exec_statement(stmt)
				case stmt.operation
				when :N_ST_SET
					i1 = conv_i(ex_expr(stmt.children[0]))
					i2 = conv_i(ex_expr(stmt.children[1]))
					handle_set(@actor, i1, i2)
				when :N_ST_SET_IF
					i1 = conv_i(ex_expr(stmt.children[0]))
					i2 = conv_i(ex_expr(stmt.children[1]))
					cond = conv_b(ex_expr(stmt.children[2]))
					handle_set_if(@actor, i1, i2, cond)
				when :N_ST_MOVE
					i1 = conv_i(ex_expr(stmt.children[1]))
					i2 = conv_i(ex_expr(stmt.children[2]))
					handle_move(@actor, stmt.children[0], i1, i2)
				when :N_ST_IF
					cond = conv_b(ex_expr(stmt.children[0]))
					i1 = conv_i(ex_expr(stmt.children[1]))
					i2 = conv_i(ex_expr(stmt.children[2]))
					handle_if(@actor, cond, i1, i2)
				when :N_ST_GOTO
					i1 = conv_i(ex_expr(stmt.children[0]))
					handle_goto(@actor, i1)
				when :N_ST_WAIT
					i1 = conv_i(ex_expr(stmt.children[0]))
					handle_wait(@actor, i1)
				when :N_ST_CALL
					handle_wait(@actor, stmt.children[0])
				when :N_ST_ADD
					v = stmt.children[0]
					i1 = conv_i(ex_expr(stmt.children[1]))
					if v.children[1] == :GLOBAL_VAR
						handle_add_global(actor, v.children[0], i1)
					else
						handle_add_local(actor, v.children[0], i1)
					end
				when :N_ST_PUT
					v = stmt.children[0]
					if stmt.children[2] # Switch
						cond = conv_b(ex_expr(stmt.children[1]))
						handle_put_switch(actor, v, cond)
					else
						i1 = conv_i(ex_expr(stmt.children[1]))
						if v.children[1] == :GLOBAL_VAR
							handle_put_global(actor, v.children[0], i1)
						else
							handle_put_local(actor, v.children[0], i1)
						end
					end
				when :N_ST_MOVIE
					handle_movie(@actor, stmt.children[0])
				end
			end
			
			# FIXME: Is the order of ex_**next** and ex_**current** right?
			def ex_expr(expr)
				return ex_log_or(expr)
			end
			
			def ex_log_or(expr)
				if expr.operation == :N_LOG_OR
					return conv_b(ex_log_and(expr.children[0])) ||
							conv_b(ex_log_or(expr.children[1]))
				else
					return ex_log_and(expr)
				end
			end
			
			def ex_log_and(expr)
				if expr.operation == :N_LOG_AND
					return conv_b(ex_equal(expr.children[0])) &&
							conv_b(ex_log_and(expr.children[1]))
				else
					return ex_equal(expr)
				end
			end
			
			def ex_equal(expr)
				if expr.operation == :N_EQUAL
					if expr.children[2] == true # ==
						return conv_i(ex_rel(expr.children[0])) ==
								conv_i(ex_equal(expr.children[1]))
					else
						return conv_i(ex_rel(expr.children[0])) !=
								conv_i(ex_equal(expr.children[1]))
					end
				else
					return ex_rel(expr)
				end
			end
			
			def ex_rel(expr)
				case expr.children[2]
				when :LESS
					return conv_i(ex_add(expr.children[0])) <
							conv_i(ex_rel(expr.children[1]))
				when :EQUAL_LESS
					return conv_i(ex_add(expr.children[0])) <=
							conv_i(ex_rel(expr.children[1]))
				when :GREATER
					return conv_i(ex_add(expr.children[0])) >
							conv_i(ex_rel(expr.children[1]))
				when :EQUAL_GREATER
					return conv_i(ex_add(expr.children[0])) >=
							conv_i(ex_rel(expr.children[1]))
				else
					return ex_add(expr)
				end
			end
			
			def ex_add(expr)
				if expr.operation == :N_ADD
					if expr.children[2] == true # +
						return conv_i(ex_mul(expr.children[0])) +
								conv_i(ex_add(expr.children[1]))
					else
						return conv_i(ex_mul(expr.children[0])) -
								conv_i(ex_add(expr.children[1]))
					end
				else
					return ex_mul(expr)
				end
			end
			
			def ex_mul(expr)
				if expr.operation == :N_MUL
					if expr.children[2] == :MUL
						return conv_i(ex_unary(expr.children[0])) *
								conv_i(ex_mul(expr.children[1]))
					elsif expr.children[2] == :DIV
						return conv_i(ex_unary(expr.children[0])) /
								conv_i(ex_mul(expr.children[1]))
					else
						return conv_i(ex_unary(expr.children[0])) %
								conv_i(ex_mul(expr.children[1]))
					end
				else
					return ex_unary(expr)
				end
			end
			
			def ex_unary(expr)
				if expr.operation == :N_MUL
					if expr.children[1] == :ADD
						return conv_i(ex_literal(expr.children[0]))
					elsif expr.children[1] == :SUB
						return - conv_i(ex_literal(expr.children[0]))
					else
						return ! conv_b(ex_literal(expr.children[0]))
					end
				else
					return ex_literal(expr)
				end
			end
			
			def ex_literal(expr)
				case expr.children[1]
				when :NUMBER
					return expr.children[0]
				when :BOOL
					return expr.children[0]
				when :FUNCTION
					return eval(expr.children[0])
				when :SWITCH
					return $game_switches[expr.children[0]] if $game_switches
					return false
				when :GLOBAL_VAR
					return $game_variables[expr.children[0]] if $game_variables
					return 0
				when :LOCAL_VAR
					return @variables[expr.children[0]]
				else
					return ex_expr(expr)
				end
			end
					
			#### Converter
			def conv_i(o)
				if o.is_a?(FalseClass)
					return 0
				elsif o.is_a?(TrueClass)
					return 1
				else
					return o.to_i
				end
			end
			
			def conv_b(o)
				if o.is_a?(Numeric)
					return o != 0
				else
					return o
				end
			end
			
		end # VM
	end
end

if Pear::AnimCEL::TEST
	vm = Pear::AnimCEL::VM.new
	vm.add("[@ 1 set @1+1 $1 @]")
	vm.start(nil)
	vm.step
	#p "STOP"
	rgss_stop
end