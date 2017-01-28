require 'cinch'
require 'cinch/plugins/identify'
require 'yaml'

require_relative "missions"

#Load config using YAML
config = YAML.load_file("config.yaml")

#Global database accessible by all threads, technically a problem, but honestly what are the chances?
$members = []
$admins = ['varzeki', 'makotoyuki']
$missions = []
$factions = []

if !config["config"].key? "admins"
    config["config"]["admins"] = config.fetch( "admins", [] )
end

#Appends bought admins to the hardcoded ones.
$admins.concat config["config"]["admins"]
#This removes eventual doubles
$admins = $admins.uniq

#Main bot definition
mobot = Cinch::Bot.new do

    #Holds threads created by methods - mostly timers
    threads = []

    #Should be called whenever the database is changed for any reason
    def update_db(cont)
        db = File.open('./database', 'w')
        db.write(Marshal.dump(cont))
        db.close
    end

    def update_factions(cont)
        db = File.open('./factions', 'w')
        db.write(Marshal.dump(cont))
        db.close
    end


    class Faction
        attr_accessor :name, :leader, :bank, :syndicate, :tier1, :tier2, :invited

        def initialize(name, leader, bank=0)
            @name = name
            @bank = bank
            @syndicate = false
            @leader = leader
            @tier1 = []
            @tier2 = []
            @invited = []
        end

        def daily_reduction
            @bank = @bank - 350
            if @bank < 0
                @syndicate = true
                return @name
            end
        end

    end

    #Class for each user
    class Member
        attr_accessor :name, :credits, :dex, :str, :int, :lck, :pvp, :mission, :daily, :crew, :crew_array, :crew_open, :fact

        #On initialization, only takes name by default
        def initialize(name, credits = 0, dex = 1, str = 1, int = 1, lck = 1)
            @name = name
            @credits = credits
            @daily = false
            @dex = dex
            @str = str
            @int = int
            @lck = lck
            @pvp = false
            @mission = false
            @crew = '%NONE'
            @crew_array = []
            @crew_open = false
            @fact = '%NONE'
        end


        #Helper methods - allows easy management of currency
        def add_trivia(amount)
            if amount < 10
                @credits = @credits + amount * 2
            else
                @credits = @credits + 20
            end
        end

        def add_uno(amount)
            @credits = @credits + amount + 50
        end


        #Toggles per user daily variable - NOT responsible for threaded timing
        def daily_claim()
            if not @daily
                @daily = true
                @credits = @credits + 250
                val = "Daily claimed!"
            else
                val = "You already claimed your daily!"
            end
            val
        end


        #Helper method to return stats in an array
        def get_stats()
            val = [@dex, @str, @int, @lck]
        end


        #
        def robbed()
            if rand() > 0.8
                amount = rand() * @credits/2
                amount = amount.round
                @credits = @credits - amount
                amount
            else
                0
            end
        end

        def pvp()
            @pvp = !@pvp
            if @pvp
                val = "Your PvP is now ON!"
            else
                val = "Your PvP is now OFF!"
            end
            val
        end
        def daily_reset()
            @daily = false
        end
        def mission_reset()
            @mission = false
        end
	    def buy(item, recipient, m)
	        if item == "kick"
                if @credits > 999
    	    	    @credits = @credits - 1000
    	    	    m.channel.kick(recipient)
    	    	    val = "User kicked!"
    	    	else
    	    	    val = "You need 1000 credits to kick someone!"
    	    	end
	        end
	        if item == "devoice"
                if @credits > 1999
    	    	    @credits = @credits - 2000
    	    	    m.channel.devoice(recipient)
    	    	    val = "User devoiced!"
    	    	else
    	    	    val = "You need 2000 credits to devoice someone!"
    	    	end
	        end
	        if item == "DEX"
    	        amount = 450 + 50 * @dex
    	    	if @credits > amount - 1
    	    	    @credits = @credits - amount
    	    	    @dex = @dex + 1
    	    	    val = "DEX upgraded! Your DEX is now #{@dex}!"
    	    	else
    	    	    val = "You need #{amount} credits to upgrade your DEX!"
    	    	end
            end
	        if item == "INT"
    	        amount = 450 + 50 * @int
    	    	if @credits > amount - 1
    	    	    @credits = @credits - amount
    	    	    @int = @int + 1
    	    	    val = "INT upgraded! Your INT is now #{@int}!"
    	    	else
    	    	    val = "You need #{amount} credits to upgrade your INT!"
    	    	end
            end
	        if item == "STR"
    	        amount = 450 + 50 * @str
    	    	if @credits > amount - 1
    	    	    @credits = @credits - amount
    	    	    @str = @str + 1
    	    	    val = "STR upgraded! Your STR is now #{@str}!"
    	    	else
    	    	    val = "You need #{amount} credits to upgrade your STR!"
    	    	end
            end
	        if item == "LCK"
    	        amount = 450 + 50 * @lck
    	    	if @credits > amount - 1
    	    	    @credits = @credits - amount
    	    	    @lck = @lck + 1
    	    	    val = "LCK upgraded! Your LCK is now #{@lck}!"
    	    	else
    	    	    val = "You need #{amount} credits to upgrade your LCK!"
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

    def get_fact(name)
        for i in $factions
            if i.name == name
                return i
            end
        end
        return '%NONE'
    end

    begin
        $members = Marshal.load File.read('./database')
        $factions = Marshal.load File.read('./factions')
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

    $missions.concat(loadMissions())

    $members.each do |i|
        i.daily_reset
        i.mission_reset
    end

    Timer(300) {
        User('taylorswift').send(".bene")
    }

    on :message, /^JOIN (#.+)$/ do |m, target|
        if $admins.include? m.user.to_s
            Channel(target).join
        end
    end

    on :message, /^SEND (#.+)/ do |m, args|
        if $admins.include? m.user.to_s
            lst = args.split(' ')
        	contents = lst[1..lst.length].join(' ')
    	    Channel(lst[0]).send(contents)
        end
    end

    on :message, /^MESSAGE (.+)/ do |m, args|
        if $admins.include? m.user.to_s
            lst = args.split(' ')
            User(lst[0]).send(lst[1..lst.length].join(' '))
        end
    end

    on :message, ".daily" do |m|
        usr = mobot.get_user(m.user.to_s, $members)
        if usr.daily == false
            threads.push Thread.new {
                sleep(86400)
                usr.daily_reset
            }
        end
        m.reply usr.daily_claim
        mobot.update_db($members)
    end

    on :message,  /^.credits/ do |m|
    	lst = m.message.split(' ')
    	if lst.length > 1
    	    m.reply mobot.get_user(lst[1], $members).credits
        else
            m.reply mobot.get_user(m.user.to_s, $members).credits
        end
    end

    on :message,  /^.attr/ do |m|
        lst = m.message.split(' ')
        if lst.length > 1
            stats = mobot.get_user(lst[1], $members).get_stats
            m.reply "DEX: #{stats[0].to_s} | STR: #{stats[1].to_s} | INT: #{stats[2].to_s} | LCK: #{stats[3].to_s}"
        end
    end

    on :message, ".attr" do |m|
        stats = mobot.get_user(m.user.to_s, $members).get_stats
        m.reply "DEX: #{stats[0].to_s} | STR: #{stats[1].to_s} | INT: #{stats[2].to_s} | LCK: #{stats[3].to_s}"
    end

    on :message, ".taytay" do |m|
        m.reply(".money")
    end

    on :message, ".pvp" do |m|
        m.reply mobot.get_user(m.user.to_s, $members).pvp
    end

    on :message, ".mission" do |m|
        mission = $missions.sample
        user = mobot.get_user(m.user.to_s, $members)
        if user.mission == false
            if not user.crew == "%NONE"
                statblock = []
                mobot.get_user(user.crew, $members).crew_array.each do |i|
                    statblock.push(mobot.get_user(i, $members).get_stats)
                end
                stats = [1, 1, 1, 1]
                statblock.each do |i|
                    4.times do |j|
                        if i[j] > stats[j]
                            stats[j] = i[j]
                        end
                    end
                end
                result = mission.attempt(stats)
                reward = (result[2] / statblock.length).round
                reward = reward + 10
                m.reply result[0]
                m.reply result[1]
                mobot.get_user(user.crew, $members).crew_array.each do |i|
                    u = mobot.get_user(i, $members)
                    if (u.credits + reward) < 1
                        user.credits = 0
                    else
                        u.credits = u.credits + reward
                    end
                end
                if reward < 0
                    reward = reward.abs
                    m.reply "That mission lost your crew #{reward} credits each!"
                else
                    m.reply "That mission gained your crew #{reward} credits each!"
                end
                user.mission = true
                mobot.update_db($members)
                sleep(180)
                user.mission = false
            else
                result = mission.attempt(user.get_stats)
                reward = result[2]
                m.reply result[0]
                m.reply result[1]
                if (user.credits + reward) < 1
                    neg = user.credits
                    user.credits = 0
                    m.reply "That mission lost you #{neg} credits! You now have 0 credits!"
                else
                    user.credits = user.credits + reward
                    current = user.credits
                    if reward < 0
                        reward = reward.abs
                        m.reply "That mission lost you #{reward} credits! You now have #{current} credits!"
                    else
                        m.reply "That mission gained you #{reward} credits! You now have #{current} credits!"
                    end
                end
                user.mission = true
                mobot.update_db($members)
                sleep(180)
                user.mission = false
            end
        else
            m.reply "You already went on a mission recently! Take a break for a minute or three."
        end
    end


    on :message, ".help" do |m|
        User(m.user.to_s).send("Hi! I'm mobot! I allow you to save up credits via playing games with other bots in irc such as UNOBot or Trivia, and eventually spend them to devoice or kick other $members, even if you don't have permission to do so. Try doing '.daily' to get started.")
        User(m.user.to_s).send('Commands are as follows:')
		User(m.user.to_s).send('.daily - Claims your daily 250 credits.')
		User(m.user.to_s).send('.credits - Shows your current balance.')
		User(m.user.to_s).send('.purchase {item} [recipient] - Purchases an item.')
		User(m.user.to_s).send('.store - Lists items for purchase.')
		User(m.user.to_s).send('.taytay - Shows current taylorswift balance. [Deprecated]')
		User(m.user.to_s).send('.rob - Pay 20 credits to attempt to rob another user.')
		User(m.user.to_s).send('.attr - Shows your current attributes.')
		User(m.user.to_s).send('.attr {username} - Shows the current attributes of another user.')
		User(m.user.to_s).send('.mission - Attempt a mission to earn credits.')
		User(m.user.to_s).send('.give {username} {amount} - Transfers some of your credits to a given user.')
		User(m.user.to_s).send('.pvp - Toggles your PvP status. [Not yet implemented.]')
		User(m.user.to_s).send('.bet {amount} - Attempt to bet some credits - double or nothing!')
		User(m.user.to_s).send('.crew start - Starts a crew with you as captain.')
		User(m.user.to_s).send('.crew join {username} - Joins another users crew, provided it is open.')
		User(m.user.to_s).send('.crew open - Opens your crew to new members.')
		User(m.user.to_s).send('.crew close - Closes your crew to new members.')
		User(m.user.to_s).send('.crew leave - Leaves the current crew, or disbands it if you are captain.')
		User(m.user.to_s).send('.crew show - Shows the status of your current crew.')
    end

    on :message, ".store" do |m|
        User(m.user.to_s).send('Welcome to the store! You can purchase each of the following using .purchase {item}')
        User(m.user.to_s).send('kick {recipient} - Kicks target user - 1000 credits')
        User(m.user.to_s).send('devoice {recipient} - Devoices target user - 2000 credits')
        User(m.user.to_s).send('DEX - Increases your Dexterity attribute - 500 + 50 for each previous upgrade')
        User(m.user.to_s).send('STR - Increases your Strength attribute - 500 + 50 for each previous upgrade')
        User(m.user.to_s).send('INT - Increases your Intelligence attribute - 500 + 50 for each previous upgrade')
        User(m.user.to_s).send('LCK - Increases your Luck attribute - 500 + 50 for each previous upgrade')
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

    on :message, /^.cmod (.+)/ do |m, arg|
        lst = arg.split(' ')
	    amount = lst[0]
	    recipient = lst[1]
	    if $admins.include? m.user.to_s
	        user = mobot.get_user(recipient, $members)
	        user.credits = user.credits + amount.to_i
	        m.reply "User credited!"
	        mobot.update_db($members)
	    else
	        m.reply "You don't have permission to do that!"
	    end
    end

    on :message, /^.admin (.+)/ do |m, arg|
        lst = arg.split(' ')
	    recipient = lst[0]
	    if (!config["admins"].include? recipient) && ($admins.include? m.user.to_s)
            if $admins.include? recipient
                $admins.delete_at($admins.find_index(recipient))
    	        m.reply "#{recipient} was removed from admins."
            else
                $admins.push(recipient)
    	        m.reply "#{recipient} was added as an admin."
            end
	    else
	        m.reply "You don't have permission to do that!"
	    end
    end

    on :message, /^.faction (.+)/ do |m, arg|
        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        m.reply lst
        if lst[0] == 'create'
            if user.fact == '%NONE'
                if lst.length > 1
                    current = mobot.get_fact(lst[1..lst.length])
                    if current == '%NONE'
                        if user.credits > 14999
                            user.credits = user.credits - 15000
                            $factions.push(Faction.new(lst[1..lst.length].join(' '), m.user.to_s))
                            user.fact = lst[1..lst.length].join(' ')
                            mobot.get_fact(user.fact).tier1.push(user.name)
                            mobot.update_db($members)
                            mobot.update_factions($factions)
                            m.reply "You pay the 15000 startup cost and create a new faction!"
                        else
                            m.reply "You need 15000 credits to start a faction!"
                        end
                    else
                        m.reply "That faction already exists!"
                    end
                else
                    m.reply "You need to give your faction a name!"
                end
            else
                m.reply "You're already in a faction!"
            end
        end
        if lst[0] == 'join'
            if user.fact == '%NONE'
                if lst.length > 1
                    fact = mobot.get_fact(lst[1..lst.length].join(' '))
                    if not fact == '%NONE'
                        if fact.invited.include? m.user.to_s
                            if user.credits > 499
                                user.credits = user.credits - 500
                                user.fact = lst[1..lst.length].join(' ')
                                fact.tier2.push(m.user.to_s)
                                fact.invited = fact.invited - [user.name]
                                joined = fact.name
                                mobot.update_db($members)
                                mobot.update_factions($factions)
                                m.reply "You paid the entry fee of 500 coins and joined #{joined}!"
                            else
                                m.reply "You don't have enough credits to pay the 500 credit entry fee!"
                            end
                        else
                            m.reply "You havn't been invited to that faction!"
                        end
                    else
                        m.reply "That faction doesn't exist!"
                    end
                else
                    m.reply "That faction doesn't exist!"
                end
            else
                m.reply "You're already in a faction!"
            end
        end
        if lst[0] == 'leave'
            if not user.fact == '%NONE'
                fact = mobot.get_fact(user.fact)
                if fact.leader == user.name
                    members = fact.tier1 + fact.tier2
                    members.each do |i|
                        mobot.get_user(i, $members).fact = '%NONE'
                    end
                    $factions.delete(fact)
                    mobot.update_db($members)
                    mobot.update_factions($factions)
                    m.reply "You disband the faction!"
                else
                    if fact.tier1.include? user.name
                        fact.tier1 = fact.tier1 - user.name
                    end
                    if fact.tier2.include? user.name
                        fact.tier2 = fact.tier1 - user.name
                    end
                    user.fact = '%NONE'
                    mobot.update_db($members)
                    mobot.update_factions($factions)
                    m.reply "You leave the faction!"
                end
            else
                m.reply "You aren't in a faction!"
            end
        end
        if lst[0] == 'invite'
            if not user.fact == '%NONE'
                fact = mobot.get_fact(user.fact)
                if fact.tier1.include? user.name
                    if lst.length > 1
                        inv = lst[1]
                        fact.invited.push(inv)
                        mobot.update_factions($factions)
                        m.reply "You just invited #{inv} to the faction!"
                    else
                        m.reply "You didn't specify a user!"
                    end
                else
                    m.reply "You don't have permission to do that!"
                end
            else
                m.reply "You aren't in a faction!"
            end
        end
        if lst[0] == 'bank'
            if not user.fact == '%NONE'
                fact = mobot.get_fact(user.fact)
                if not fact.syndicate
                    if lst.length > 1
                        if 0 + lst[1].to_i > 1
                            if lst[1].to_i < user.credits
                                if not fact.bank + lst[1].to_i > 3000
                                    fact.bank = fact.bank + lst[1].to_i
                                    user.credits = user.credits - lst[1].to_i
                                    amount = fact.bank
                                    mobot.update_factions($factions)
                                    m.reply "Deposit successful! The faction now has #{amount}!"
                                else
                                    m.reply "The bank can't hold that much!"
                                end
                            else
                                m.reply "You don't have that many credits!"
                            end
                        else
                            m.reply "Please bank a valid amount!"
                        end
                    else
                        m.reply "Please bank a valid amount!"
                    end
                else
                    m.reply "Your faction is a syndicate, and can't bank money!"
                end
            else
                m.reply "You aren't in a faction!"
            end
        end
        if lst[0] == 'show'
            if not user.fact == '%NONE'
                fact = mobot.get_fact(user.fact)
                nm = fact.name
                bnk = fact.bank
                if fact.syndicate
                    syn = "Syndicate"
                else
                    syn = "Corporation"
                end
                members = fact.tier1 + fact.tier2
                lead = fact.leader
                m.reply "You are in the faction #{nm}, which is lead by #{lead}, has a balance of #{bnk}, and has members #{members}."
            else
                m.reply "You aren't in a faction!"
            end
        end
    end




    on :message, /^.crew (.+)/ do |m, arg|
        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        if lst[0] == 'start'
            if user.crew == "%NONE"
                user.crew = user.name
                user.crew_array = [user.name]
                user.crew_open = false
                mobot.update_db($members)
                m.reply "You started a crew!"
            else
                m.reply "You're already in a crew!"
            end
        end
        if lst[0] == 'help'
            m.user.send('Available crew commands:')
            m.user.send('.crew start')
            m.user.send('.crew join {leader}')
            m.user.send('.crew leave')
            m.user.send('.crew open')
            m.user.send('.crew close')
            m.user.send('.crew show')
        end
        if lst[0] == 'join'
            if user.crew == "%NONE"
                user2 = mobot.get_user(lst[1], $members)
                if not user2.crew == user2.name
                    m.reply "That user isn't a crew captain!"
                else
                    if user2.crew_open == true
                        if user2.crew_array.length > 2
                            m.reply "That users crew is full!"
                        else
                            user2.crew_array.push(user.name)
                            user.crew = user2.name
                            cname = user2.name
                            mobot.update_db($members)
                            m.reply "You just joined the crew of #{cname}!"
                        end
                    else
                        m.reply "That users crew is closed!"
                    end
                end
            else
                m.reply "You're already in a crew!"
            end
        end
        if lst[0] == 'open'
            if user.crew == user.name
                if not user.crew_open
                    user.crew_open = true
                    m.reply "Your crew is now open!"
                    mobot.update_db($members)
                else
                    m.reply "Your crew is already open!"
                end
            else
                if user.crew == "%NONE"
                    m.reply "You aren't in a crew!"
                else
                    m.reply "You aren't the captain of this crew!"
                end
            end
        end
        if lst[0] == 'close'
            if user.crew == user.name
                if user.crew_open
                    user.crew_open = false
                    mobot.update_db($members)
                    m.reply "Your crew is now closed!"
                else
                    m.reply "Your crew is already closed!"
                end
            else
                if user.crew == "%NONE"
                    m.reply "You aren't in a crew!"
                else
                    m.reply "You aren't the captain of this crew!"
                end
            end
        end
        if lst[0] == 'leave'
            if user.crew == user.name
                user.crew_array.each do |i|
                    j = mobot.get_user(i, $members)
                    j.crew = "%NONE"
                end
                user.crew_array = []
                mobot.update_db($members)
                m.reply "You disband the crew!"
            else
                user2 = mobot.get_user(user.crew, $members)
                user2.crew_array = user2.crew_array - [user.name]
                user.crew = "%NONE"
                mobot.update_db($members)
                m.reply "You leave the crew!"
            end
        end
        if lst[0] == 'show'
            if user.crew == "%NONE"
                m.reply "You aren't in a crew!"
            else
                open = mobot.get_user(user.crew, $members).crew_open
                if open
                    status = "OPEN"
                else
                    status = "CLOSED"
                end
                owner = user.crew
                members = mobot.get_user(user.crew, $members).crew_array
                m.reply "This #{status} crew is owned by #{owner} and has members #{members}."
            end
        end
    end



    on :message, /^.rob (.+)/ do |m, arg|
        lst = arg.split(' ')
        robber = mobot.get_user(m.user.to_s, $members)
        victim = mobot.get_user(lst[0], $members)
        if robber.credits > 19
            if robber == victim
                m.reply "You're seriously trying to rob yourself? What a masochist!"
            end
            amount = victim.robbed
            robber.credits = robber.credits + amount - 20
            current = robber.credits
            if amount > 0
                m.reply "You successfully stole #{amount} credits! You now have #{current} credits!"
            else
                m.reply "You failed to steal anything! You now have #{current} credits!"
            end
            mobot.update_db($members)
        else
            m.reply "It costs 20 credits to rob someone!"
        end
    end

    on :message, /^.purchase (.+)/ do |m, arg|
        lst = arg.split(' ')
        item = lst[0]
        recipient = lst[1]
        m.reply mobot.get_user(m.user.to_s, $members).buy(item, recipient, m)
        mobot.update_db($members)
    end

    on :message, ".bots" do |m|
        m.reply "[Ruby] https://github.com/Varzeki/mobot | Try using .help for commands!"
    end

    on :message, ".migrate" do |m|
        if $admins.include? m.user.to_s
            m.reply "Migrating database..."
            new_db = []
            $members.each do |i|
                new_db.push(Member.new(i.name, i.credits, i.dex, i.str, i.int, i.lck))
            end
            $members = new_db
            mobot.update_db($members)
            m.reply "Done!"
  	    else
  	        m.reply "You don't have permission to do that!"
  	    end
    end

    on :message, /^.bet (.+)/ do |m, arg|
        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        if lst[0].to_i > 1
            if user.credits - lst[0].to_i > -1
                if rand() > 0.52
                    user.credits = user.credits + lst[0].to_i
                    amount = user.credits
                    m.reply "Congratulations, you won! You now have #{amount} credits!"
                else
                    user.credits = user.credits - lst[0].to_i
                    amount = user.credits
                    m.reply "You lost! You now have #{amount} credits!"
                end
            end
			mobot.update_db($members)
        end
    end

	on :message, /^.give (.+) (\d+)/ do |m, target, amount|
		userGiver = mobot.get_user(m.user.to_s, $members)
		userReciever = mobot.get_user(target,$members)
		amount = Integer(amount)

		fee = (amount*0.01).ceil

		if userGiver.credits > (amount+fee)
			userGiver.credits -= (amount + fee)
			userReciever.credits += amount
			m.reply "#{userGiver.name} transfered #{amount} credits to #{userReciever.name}. #{fee} credits were charged for the transaction."
			mobot.update_db($members)
		else
			m.reply "You need transfered #{amount+fee} credits to transfer #{amount}."
		end
	end
end

#Set logging
mobot.loggers << Cinch::Logger::FormattedLogger.new(File.open("./mobot.log", "a"))
mobot.loggers.level = :debug
mobot.loggers.first.level = :info

#Start
mobot.start
