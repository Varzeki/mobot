require 'cinch'
require "cinch/plugins/identify"
require 'yaml'

#Load config
config = YAML.load_file("config.yaml")
members = []

#Bot
hsbot = Cinch::Bot.new do
    
    threads = []

    def update_db(cont)
        db = File.open('./database', 'w')
        db.write(Marshal.dump(cont))
        db.close
    end

    class Member
        attr_accessor :name, :coins
        def initialize(name, coins = 0)
            @name = name
            @coins = coins
            @daily = false
        end
        def add_trivia(amount)
            @coins = @coins + amount * 2
        end
        def add_uno(amount)
            @coins = @coins + amount
        end
        def daily()
            if not @daily
                @daily = true
                @coins = @coins + 250
		val = "Daily claimed!"
	    else
		val = "You already claimed your daily!"
            end
	    val
        end
        def mugged(message)
	    if rand() > 0.8
	        amount = rand() * @coins/2
		amount = amount.round
		@coins = @coins - amount
		message.reply "You successfully stole #{amount} coins!"
		amount
	    else
		message.reply "You failed to steal anything!"
	        0
	    end
	end
	def daily_reset()
	    @daily = false
	end
	def buy(item, recipient, m)
	    if item == "kick"
                if @coins > 999
		    @coins = @coins - 1000
		    m.channel.kick(recipient)
		    val = "User kicked!"
		else
		    val = "You need 1000 coins to kick someone!"
		end
	    end
	    if item == "devoice"
                if @coins > 1999
		    @coins = @coins - 2000
		    m.channel.devoice(recipient)
		    val = "User devoiced!"
		else
		    val = "You need 2000 coins to devoice someone!"
		end
	    end
	    val
	end
    end

    def get_user(user, mem)
        for i in mem
	    if i.name == user
	        return i
	    end
	end
	return "%INVALID"
    end

    begin
        members = Marshal.load File.read('./database')
    rescue
	puts "Failed to load database!"
    end
    
    #Initial Bot Config
    configure do |c|
        c.name = config['config']['realname']
        c.server = config['config']['server']
        c.port = config['config']['port'].to_s
        c.nick = config['config']['nick'].to_s
        c.channels = config['config']['channels']
	c.delay_joins = :identified
        c.plugins.plugins = [Cinch::Plugins::Identify]
	c.plugins.options[Cinch::Plugins::Identify] = {
	    :password => config['config']['password'],
	    :type => :nickserv,
	}
    end
    


    Timer(86400) {
        for i in members do
            i.trivia = 0
            i.uno = 0
	    i.daily = false
        end
    }

    Timer(300) {
        User('taylorswift').send(".bene")
    }


    on :message, ".reg" do |m|
	unless members.any? {|i| i.name == m.user.to_s }
	    members << Member.new(m.user.to_s)
            m.reply "User registered!"
	    hsbot.update_db(members)
	else
	    m.reply "User already registered!"
	end
    end

    on :message, ".daily" do |m|
	usr = hsbot.get_user(m.user.to_s, members)
	if not usr == "%INVALID"
	    m.reply usr.daily
	    threads.push Thread.new {
	        sleep(86400)
		usr.daily_reset
	    }
	    hsbot.update_db(members)
	else
	    m.reply "You aren't registered!"
	end
    end

    on :message, ".coins" do |m|
        for i in members do
            if i.name == m.user.to_s
                m.reply i.coins
		break
            end
        end
    end

    on :message, ".taytay" do |m|
	m.reply(".money")
    end

    on :message, ".help" do |m|
	User(m.user.to_s).send('Commands are as follows:')
	User(m.user.to_s).send('.daily - Claims your daily 250 coins')
	User(m.user.to_s).send('.coins - Shows your current balance')
	User(m.user.to_s).send('.purchase {item} {recipient} - Purchases a "devoice" or "kick" for target user')
	User(m.user.to_s).send('.taytay - Shows current taylorswift balance')
	User(m.user.to_s).send('.register - Registers your nick into the database')
    end

    on :message do |m|
	if m.user.to_s == "Trivia"
	    lst = m.message.split(' ')
            if lst[0] == "Winner:"
		for i in members
	            if i.name == lst[1].chop
	                i.add_trivia(lst[lst.index("Points:")+1].chop.to_i)
		        hsbot.update_db(members)
		    end
		end
	    end
	end
    end

    on :message, /^.credit (.+)/ do |m, arg|
        lst = arg.split(' ')
	amount = lst[0]
	recipient = lst[1]
	if m.user.to_s == 'varzeki'
	    for i in members do
	        if i.name == recipient
	            i.coins = i.coins + amount.to_i 
	            m.reply "User credited!"
		    hsbot.update_db(members)
                end
	    end
	else
	    m.reply "You don't have permission to do that!"
	end
    end
	
    on :message, /^.mug (.+)/ do |m, arg|
        lst = arg.split(' ')
	mugger = hsbot.get_user(m.user.to_s, members)
	muggee = hsbot.get_user(lst[0], members)
	if not mugger == "%INVALID"
	    if mugger.coins > 19
	        if mugger == muggee
	            m.reply "You're seriously trying to mug yourself? What a masochist!"
                end
	        if not muggee == "%INVALID"
		    mugger.coins = mugger.coins - 20
	            mugger.coins = mugger.coins + muggee.mugged(m)
	            hsbot.update_db(members)
	        else
	            m.reply "The person you are trying to mug is not registered!"
	        end
	     else
	         m.reply "It costs 20 coins to mug someone!"
             end
	else
	    m.reply "You are not registered!"
	end
    end

    on :message, /^.purchase (.+)/ do |m, arg|
        lst = arg.split(' ')
	item = lst[0]
	recipient = lst[1]
	for i in members do
	    if i.name == m.user.to_s
	        m.reply i.buy(item, recipient, m)
		hsbot.update_db(members)
            end
	end
    end
end


#Set logging
hsbot.loggers << Cinch::Logger::FormattedLogger.new(File.open("./hsbot.log", "a"))
hsbot.loggers.level = :debug
#hsbot.loggers.first.level = :info

#Start
hsbot.start

