require 'rubygems'
require 'data_mapper' # requires all the gems listed above
require 'dm-migrations'
require 'ruby-progressbar'

# If you want the logs displayed you have to do this before the call to setup
DataMapper::Logger.new($stdout, :debug)

# An in-memory Sqlite3 connection:
#DataMapper.setup(:default, 'sqlite::memory:')

# A Sqlite3 connection to a persistent database

file_root = File.dirname(File.absolute_path(__FILE__))
db_file = ENV['DB_FILE'] || "#{file_root}/test_data.db"
#puts "db_file = #{db_file}"

#DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, "sqlite://#{db_file}")
DataMapper::Model.raise_on_save_failure = true

# Load all dbmodel files
Dir.glob(file_root + "/dbmodel/*.rb").each do |file| 
  require file
end

DataMapper.finalize
DataMapper.auto_upgrade!

#def initialize_tables
#  ReplacementMask.initialize_table
#end
#
#def clean_database
#	#DataMapper.drop
#	DataMapper.auto_migrate!
#end
#
#def create_database_with_csv(file)
#  headers = {}
#  data = []
#  count = 0
#
#  puts "Database generation from #{file}.\n"
#
#  puts "Reading CSV file."
#  progressbar = ProgressBar.create(:starting_at => 0, :total => nil) 
#  CSV.foreach(file) do |row|
#    if(count == 0)
#      i = 0
#      row.each do |h|
#        headers[i] = h; i += 1
#      end
#    else
#      i = 0
#      d = {}
#      row.each do |v|
#        d[headers[i]] = v
#        i += 1
#      end
#      data.push(d)
#    end
#  
#    count += 1
#    progressbar.increment
#  end
#  progressbar.total = count
#  puts "Read #{count} number of rows."
#  
#  
#  # Setting up CpuVersion table
#  print "Filling CpuVersion table. "
#  cpus = headers.select { |k,v| v =~ /D: /}.map { |k,v| v.split(' ')[1..-1].join(' ') }
#  cpus.each do |cpu|
#    CpuVersion.create(name: cpu);
#  end
#  puts "DONE"
#  
#  line = 0
#  puts "Generating all data:"
#  #progressbar = ProgressBar.create(:starting_at => 0, :total => count) 
#  progressbar = ProgressBar.create( :format         => '%a (%c/%C) %bᗧ%i %p%% %t',
#                                    :progress_mark  => ' ',
#                                    :remainder_mark => '･',
#                                    :starting_at    => 0,
#                                    :total          => count)
#  data.each do |elem|
#    #print elem
#    line += 1
#  
#    #next if(line < 0 || line > 485)
#  
#    flags = ['aa', 'cc', 'd', 'di', 'f', 'T', 'x', 'zz']
#    mnemonic = elem['Mnemonic']
#    if(mnemonic !~ /^\s*$/)
#      opcode = ''
#      32.times do |n|
#        n = (n < 10) ? "0#{n}" : "#{n}"
#        opcode = "#{elem[n]}#{opcode}"
#      end
#  
#      if(opcode =~ /^\s*$/)
#        puts "Empty opcode for line #{line} with mnemonic #{mnemonic}"
#      end
#  
#      # Create the instruction elements (Instruction)
#      instruction = Instruction.create({
#        mnemonic: elem['Mnemonic'],
#        opcode: opcode,
#        class: elem['Class'],			
#        subclass: elem['Subclass'],
#  
#        #flagZ: elem['Flag: Z'] == 'Y' ? true : (elem['Flag:Z'] == 'N' ? false : nil),
#        #flagN: elem['Flag: N'] == 'Y' ? true : (elem['Flag:Z'] == 'N' ? false : nil),
#        #flagC: elem['Flag: C'] == 'Y' ? true : (elem['Flag:Z'] == 'N' ? false : nil),
#        #flagV: elem['Flag: V'] == 'Y' ? true : (elem['Flag:Z'] == 'N' ? false : nil),
#        #flagS: elem['Flag: S'] == 'Y' ? true : (elem['Flag:Z'] == 'N' ? false : nil),
#      })
#  
#      # Setting up the flags
#      flags.each do |flag|
#        if(elem[flag] && elem[flag] !~ /^\s*$/)
#          insn_flag = InstructionFlag.first(type: flag, mnemonic_patch: elem[flag])
#          insn_flag = InstructionFlag.new(type: flag, mnemonic_patch: elem[flag]) if(insn_flag.nil?) 
#          insn_flag.instructions <<= instruction
#          insn_flag.save!
#        end
#      end
#  
#      # Setting up CpuVersion relations
#      CpuVersion.all.each do |cpu|
#        available = elem["D: #{cpu.name}"]
#        if(available =~ /S/)
#          ConditionalCpuInstructionRelation.create(instruction: instruction, cpu_version: cpu)	
#        elsif(available =~ /U/)
#          # Do nothing
#        elsif(available =~ /O/)
#          condition = elem["C: #{cpu.name}"]
#          puts "Warning: Optional availability for instruction at line #{line} has empty condition for CPU version #{cpu.name}" if(condition.nil? || condition =~ /^\s*$/)
#          ConditionalCpuInstructionRelation.create(
#            condition: condition,
#            instruction: instruction, 
#            cpu_version: cpu
#          )	
#        else
#          puts "Warning: Instruction at line #{line} has no information on availability for '#{cpu.name}' version."
#        end
#  
#      end
#  
#      # Setup Operand related tables (InstructionOperand, Operand)
#      operands = []
#  
#      3.times do |op_n|
#        op_name = elem["Opr#{op_n+1}"]
#        operands <<= op_name if(op_name && op_name !~ /^\s*$/)
#      end
#
#      # Add opcode limm bits to instruction
#      if(operands.select { |op| op =~ /limm/ }.size > 0)
#        instruction.opcode += Array.new(32) { 'l' }.join('')
#        #puts instruction.opcode
#      end
#  
#      op_n = 0
#
#      operands.each do |op_name|
#        operand_type = OperandType.first(name: op_name)
#        if(operand_type.nil?)
#          operand_type = OperandType.create({
#            name: op_name
#          })
#        end
#  
#        instruction_operand = InstructionOperand.new({
#          number: op_n,
#        })
#        opcode = instruction.opcode
#        instruction_operand.parse_and_set_mask(instruction.opcode, op_name.chars.first, operands )
#        instruction_operand.operand_type = operand_type
#        instruction_operand.instruction = instruction
#        instruction_operand.save!
#  
#        op_n += 1
#      end
#    end
#  
#    progressbar.increment
#  end
#end
