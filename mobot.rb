require 'cinch'
require "cinch/plugins/identify"
require 'yaml'

#Load config
config = YAML.load_file("config.yaml")
$members = []

#Bot
mobot = Cinch::Bot.new do
    
    threads = []

    def update_db(cont)
        db = File.open('./database', 'w')
        db.write(Marshal.dump(cont))
        db.close
    end

    class Member
        attr_accessor :name, :coins
        def initialize(name, coins = 0, dex = 0, str = 0, int = 0, lck = 0)
            @name = name
            @coins = coins
            @daily = false
	    @dex = dex
	    @str = str
	    @int = int
	    @lck = lck
        end
        def add_trivia(amount)
            @coins = @coins + amount * 2
        end
        def add_uno(amount)
            @coins = @coins + amount + 50
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
        def get_stats()
            [@dex, @str, @int, @lck]
        end
        def robbed(message)
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
	new = Member.new(user)
	$members << new
	update_db($members)
	return new
    end

    begin
        $members = Marshal.load File.read('./database')
    rescue
	puts "Failed to load database!"
    end
    
    #Initial Bot Config
    configure do |c|
        c.realname = config['config']['realname']
        c.user = config['config']['realname']
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
    
    $members.each do |i|
        i.daily_reset
    end

    Timer(300) {
        User('taylorswift').send(".bene")
    }

    on :message, /^JOIN (#.+)$/ do |m, target|
        Channel(target).join
    end

    on :message, /^SEND (.+)/ do |m, args|
        lst = args.split(' ')
        User(lst[0]).send(lst[1..lst.length].join(' '))
    end

    on :message, ".daily" do |m|
	usr = mobot.get_user(m.user.to_s, $members)
	m.reply usr.daily
	    threads.push Thread.new {
	        sleep(86400)
		usr.daily_reset
	    }
	    mobot.update_db($members)
    end

    on :message, ".coins" do |m|
        m.reply mobot.get_user(m.user.to_s, $members).coins
    end

    on :message, ".stats" do |m|
        stats = mobot.get_user(m.user.to_s, $members).get_stats
        m.reply "DEX: #{stats[0]} | STR: #{stats[1]} | INT: #{stats[2]} | LCK: #{stats[3]}"
    end

    on :message, ".taytay" do |m|
	m.reply(".money")
    end

    on :message, ".help" do |m|
        User(m.user.to_s).send("Hi! I'm mobot! I allow you to save up coins via playing games with other bots in irc such as UNOBot or Trivia, and eventually spend them to devoice or kick other $members, even if you don't have permission to do so. Try doing '.daily' to get started.")
	User(m.user.to_s).send('Commands are as follows:')
	User(m.user.to_s).send('.daily - Claims your daily 250 coins')
	User(m.user.to_s).send('.coins - Shows your current balance')
	User(m.user.to_s).send('.purchase {item} {recipient} - Purchases a "devoice" or "kick" for target user')
	User(m.user.to_s).send('.taytay - Shows current taylorswift balance')
	User(m.user.to_s).send('.rob - Pay 20 coins to attempt to rob another user')
    end

    on :message do |m|
	if m.user.to_s == "Trivia"
	    lst = m.message.split(' ')
            if lst[0] == "Winner:"
	        mobot.get_user(lst[1].chop, $members).add_trivia(lst[lst.index("Points:")+1].chop.to_i)
	        mobot.update_db($members)
	    end
	end
    end

    on :message do |m|
	if m.user.to_s == "UNOBot"
	    lst = m.message.split(' ')
            if lst[1] == "gains"
	        mobot.get_user(m.user.to_s, $members).add_uno(lst[2].to_i)
	    end
	end
    end

    on :message, /^.credit (.+)/ do |m, arg|
        lst = arg.split(' ')
	amount = lst[0]
	recipient = lst[1]
	if m.user.to_s == 'varzeki'
	    user = mobot.get_user(recipient, $members)
	    user.coins = user.coins + amount.to_i
	    m.reply "User credited!"
	    mobot.update_db($members)
	else
	    m.reply "You don't have permission to do that!"
	end
    end
	
    on :message, /^.rob (.+)/ do |m, arg|
        lst = arg.split(' ')
	robber = mobot.get_user(m.user.to_s, $members)
	victim = mobot.get_user(lst[0], $members)
	if robber.coins > 19
	    if robber == victim
	        m.reply "You're seriously trying to rob yourself? What a masochist!"
	    end
	    robber.coins = robber.coins + victim.robbed(m) - 20
	    mobot.update_db($members)
	else
	    m.reply "It costs 20 coins to rob someone!"
	end
    end

    on :message, /^.purchase (.+)/ do |m, arg|
        lst = arg.split(' ')
	item = lst[0]
	recipient = lst[1]
	m.reply mobot.get_user(m.user.to_s, $members).buy(item, recipient, m)
	mobot.update_db($members)
    end
end


#Set logging
mobot.loggers << Cinch::Logger::FormattedLogger.new(File.open("./mobot.log", "a"))
mobot.loggers.level = :debug
#mobot.loggers.first.level = :info

#Start
mobot.start

