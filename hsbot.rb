require 'cinch'
require "cinch/plugins/identify"
require 'yaml'

#Load config
config = YAML.load_file("config.yaml")

members = []

#Bot
robbot = Cinch::Bot.new do

    class Member
        attr_accessor :name, :coins, :trivia, :uno
        def initialize(name, coins = 0, trivia = 0, uno = 0)
            @name = name
            @coins = coins
            @trivia = trivia
            @uno = uno
            @daily = false
        end
        def add_trivia(amount)
            if not @trivia > 199
                @trivia = @trivia + amount * 2
                @coins = @coins + amount * 2
            end
        end
        def add_uno(amount)
            if not @uno > 299
                @uno = @uno + amount
                @coins = @coins + amount
            end
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

    
    #Initial Bot Config
    configure do |c|
        c.name = config['config']['realname']
        c.server = config['config']['server']
        c.port = config['config']['port'].to_s
        c.nick = config['config']['nick'].to_s
        c.channels = config['config']['channels']
	#c.delay_joins = :identified
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
            i.daily_reset
        end
    }

    Timer(300) {
        User('taylorswift').send(".bene")
    }

    on :message, ".register" do |m|
	unless members.any? {|i| i.name == m.user.to_s }
	    members << Member.new(m.user.to_s)
            m.reply "User registered!"
	else
	    m.reply "User already registered!"
	end
    end

    on :message, ".daily" do |m|
	found = false
        for i in members do
            if i.name == m.user.to_s
	        found = true
                m.reply i.daily()
		break
            end
        end
	if not found
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
                end
	    end
	else
	    m.reply "You don't have permission to do that!"
	end
    end
	

    on :message, /^.purchase (.+)/ do |m, arg|
        lst = arg.split(' ')
	item = lst[0]
	recipient = lst[1]
	for i in members do
	    if i.name == m.user.to_s
	        m.reply i.buy(item, recipient, m)
            end
	end
    end
end


#Set logging
robbot.loggers << Cinch::Logger::FormattedLogger.new(File.open("./robbot.log", "a"))
robbot.loggers.level = :debug
#robbot.loggers.first.level = :info

#Start
robbot.start

