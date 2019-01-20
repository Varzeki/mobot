require 'cinch'
# require 'cinch/plugins/identify'
require 'yaml'

require_relative 'missions'

#Load config using YAML
config = YAML.load_file('config.yaml')
force_mobot_channel = false

#Global database accessible by all threads, technically a problem, but honestly what are the chances?
$members = []
$admins = ['varzeki']
$missions = []
$factions = []

if !config.key? 'admins'
    config['admins'] = config.fetch( 'admins', [] )
end

$admins.concat config['admins']

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

    def create_item()
        rng = rand()
        if rng < 0.6
            prefix = 'Regulation'
            stats = [0.1,0.1,0.1,0.1,0.1,0.1]
            value = rand() * 1000
        elsif rng < 0.865
            prefix = 'Industrial'
            stats = [0.3,0.3,0.3,0.3,0.3,0.3]
            value = rand() * 4000
        elsif rng < 0.94
            prefix = 'Aftermarket'
            stats = [0.5,0.5,0.5,0.5,0.5,0.5]
            value = rand() * 7000
        elsif rng < 0.975
            prefix = 'Illegal'
            stats = [0.7,0.7,0.7,0.7,0.7,0.7]
            value = rand() * 10000
        elsif rng < 0.995
            prefix = 'Starframed'
            stats = [0.9,0.9,0.9,0.9,0.9,0.9]
            value = rand() * 15000
        else
            prefix = 'Zekiforged'
            stats = [1.5,1.5,1.5,1.5,1.5,1.5]
            value = 100000
        end
        weapon = ['Arclance', 'Dynawrench', 'Gravaxe', 'Fusion Rifle', 'Neuralyzer', 'Gauss Matrix', 'Implant', 'Bionics', 'Psiglass'].sample
        element = ['Aer', 'Terra', 'Aques', 'Fyr', 'Flux', 'Alica'].sample
        if element == 'Aer'
            stats[0] += 0.2
        elsif element =='Terra'
            stats[1] += 0.2
        elsif element =='Aques'
            stats[2] += 0.2
        elsif element == 'Fyr'
            stats[3] += 0.2
        elsif element == 'Flux'
            stats[4] += 0.2
        else
            stats[5] += 0.2
        end

        name = '#{prefix} #{weapon} of #{element}'
        [name, stats, value]
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
        attr_accessor :name, :credits, :dex, :str, :int, :lck, :pvp, :mission, :daily, :crew, :crew_array, :crew_open, :fact, :access, :inventory, :item, :ap

        #On initialization, only takes name by default
        def initialize(name, credits = 0, dex = 1, str = 1, int = 1, lck = 1, crew = '%NONE', crew_array = [], crew_open = false, access = 0, inventory = ['%NONE'], item = ['%NONE'], ap = 5, psi = 1, acc = 1)
            @name = name
            @credits = credits
            @daily = false
            @dex = dex
            @str = str
            @int = int
            @lck = lck
            @pvp = false
            @mission = false
            @crew = crew
            @crew_array = crew_array
            @crew_open = crew_open
            @fact = '%NONE'
            @access = access
            @inventory = inventory
            @item = item
            @ap = ap
            @psi = psi
            @acc = acc
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

        def show_inventory()
            if @inventory == ['%NONE']
                val = 'Your inventory is empty!'
            else
                val = []
                @inventory.each do |i|
                    val.push(i[0])
                end
            end
            val
        end

        def equip(slot)
            val = []
            if @inventory == ['%NONE']
                val.push 'Your inventory is empty!'
            elsif not @inventory.length >= slot
                val.push 'That\'s not a valid item!'
            elsif slot < 1
                val.push 'That\'s not a valid item!'
            else
                if not @item == '%NONE'
                    @inventory.push @item
                    val.push 'You unequip your #{@item[0]}!'
                end
                @item = @inventory[slot-1]
                @inventory.delete_at(slot-1)
                val.push 'You equip your #{item[0]}!'
            end
            val
        end

        #Helper method to return stats in an array
        def get_stats()
            val = [@dex, @str, @int, @lck, @psi, @acc]
        end

        def get_modded_stats()
            if item != ['%NONE']
                val = []
                val.push round(@dex + (@item[1][0]*@dex))
                val.push round(@str + (@item[1][1]*@str))
                val.push round(@int + (@item[1][2]*@int))
                val.push round(@lck + (@item[1][3]*@lck))
                val.push round(@psi + (@item[1][4]*@psi))
                val.push round(@acc + (@item[1][5]*@acc))
            else
                val = [@dex, @str, @int, @lck, @psi, @acc]
            end
            val
        end

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
                val = 'Your PvP is now ON!'
            else
                val = 'Your PvP is now OFF!'
            end
            val
        end

        def buy(item, recipient, m)
            if item.downcase == 'kick'
                if @credits > 999
                    @credits = @credits - 1000
                    if recipient == config['config']['nick']
                        recipient = @name
                end
                m.channel.kick(recipient)
                val = 'User kicked!'
                else
                    val = 'You need 1000 credits to kick someone!'
                end
            end
            if item.downcase == 'devoice'
                if @credits > 1999
                    @credits = @credits - 2000
                    m.channel.devoice(recipient)
                    val = 'User devoiced!'
                else
                    val = 'You need 2000 credits to devoice someone!'
                end
            end
            if item.downcase == 'dex'
                amount = 450 + 50 * @dex
                if @credits > amount - 1
                    @credits = @credits - amount
                    @dex = @dex + 1
                    val = 'DEX upgraded! Your DEX is now #{@dex}!'
                else
                    val = 'You need #{amount} credits to upgrade your DEX!'
                end
            end
            if item.downcase == 'int'
                amount = 450 + 50 * @int
                if @credits > amount - 1
                    @credits = @credits - amount
                    @int = @int + 1
                    val = 'INT upgraded! Your INT is now #{@int}!'
                else
                    val = 'You need #{amount} credits to upgrade your INT!'
                end
            end
            if item.downcase == 'str'
                amount = 450 + 50 * @str
                if @credits > amount - 1
                    @credits = @credits - amount
                    @str = @str + 1
                    val = 'STR upgraded! Your STR is now #{@str}!'
                else
                    val = 'You need #{amount} credits to upgrade your STR!'
                end
            end
            if item.downcase == 'lck'
                amount = 450 + 50 * @lck
                if @credits > amount - 1
                    @credits = @credits - amount
                    @lck = @lck + 1
                    val = 'LCK upgraded! Your LCK is now #{@lck}!'
                else
                    val = 'You need #{amount} credits to upgrade your LCK!'
                end
            end
            if item.downcase == 'psi'
                amount = 450 + 50 * @psi
                if @credits > amount - 1
                    @credits = @credits - amount
                    @psi = @psi + 1
                    val = 'PSI upgraded! Your PSI is now #{@psi}!'
                else
                    val = 'You need #{amount} credits to upgrade your PSI!'
                end
            end
            if item.downcase == 'acc'
                amount = 450 + 50 * @acc
                if @credits > amount - 1
                    @credits = @credits - amount
                    @acc = @acc + 1
                    val = 'ACC upgraded! Your ACC is now #{@acc}!'
                else
                    val = 'You need #{amount} credits to upgrade your ACC!'
                end
            end
            if item.downcase == 'access'
                amount = 2000 + (@access * 1500)
                if @credits > amount - 1
                    @credits = @credits - amount
                    @access = @access + 1
                    User('ChanServ').send('ACCESS #mobot ADD #{@name} #{@access}')
                    val = 'Access increased! Your access is now #{@access}!'
                else
                    val = 'You need #{amount} credits to increase your access!'
                end
            end
            val
        end
    end


    def get_user(user, mem)
        for i in mem
            if i.name == user.downcase
                return i
            end
        end
        newu = Member.new(user.downcase)
        $members << newu
        update_db($members)
        return newu
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
        puts 'Failed to load database!'
    end

    #Initial Bot Config
    configure do |c|
        c.realname = config['config']['realname']
        c.user = config['config']['realname']
        c.server = config['config']['server']
        c.port = config['config']['port'].to_s
        c.nick = config['config']['nick'].to_s
        c.channels = config['config']['channels']
        # c.delay_joins = :identified
        # c.plugins.plugins = [Cinch::Plugins::Identify]
        # c.plugins.options[Cinch::Plugins::Identify] = {
        #     :password => config['config']['password'],
        #     :type => :nickserv,
        # }
    end

    $missions.concat(loadMissions())

    on :connect do
        Kernel.loop {
            $members.each do |i|
                if not i.ap >= 16
                    i.ap = i.ap + 1
                end
            end
            Channel('#mobot').send('User Action Points have been updated!')
            sleep(3600)
        }
    end

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

    on :message,  /^credits/ do |m|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = m.message.split(' ')
        if lst.length > 1
            m.reply m.user.to_s + ': ' + mobot.get_user(lst[1], $members).credits.to_s
        else
            m.reply m.user.to_s + ': ' + mobot.get_user(m.user.to_s, $members).credits.to_s
        end
    end

    on :message,  /^attr/ do |m|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = m.message.split(' ')
        if lst.length > 1
            stats = mobot.get_user(lst[1], $members).get_stats
            m.reply m.user.to_s + ': ' + 'DEX: #{stats[0].to_s} | STR: #{stats[1].to_s} | INT: #{stats[2].to_s} | LCK: #{stats[3].to_s} | PSI: #{stats[4].to_s} | ACC: #{stats[5].to_s}'
        else
            stats = mobot.get_user(m.user.to_s, $members).get_stats
            m.reply m.user.to_s + ': ' + 'DEX: #{stats[0].to_s} | STR: #{stats[1].to_s} | INT: #{stats[2].to_s} | LCK: #{stats[3].to_s} | PSI: #{stats[4].to_s} | ACC: #{stats[5].to_s}'
        end
    end

    on :message, 'pvp' do |m|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        m.reply m.user.to_s + ': ' + mobot.get_user(m.user.to_s, $members).pvp
    end

    on :message, 'mission' do |m|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        mission = $missions.sample
        user = mobot.get_user(m.user.to_s, $members)
        if user.ap > 0
            user.ap = user.ap - 1
            if not user.crew == '%NONE'
                statblock = []
                mobot.get_user(user.crew, $members).crew_array.each do |i|
                    statblock.push(mobot.get_user(i, $members).get_modded_stats)
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
                m.reply m.user.to_s + ': ' + result[0]
                m.reply m.user.to_s + ': ' + result[1]
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
                    m.reply m.user.to_s + ': ' + 'That mission lost your crew #{reward} credits each!'
                else
                    m.reply m.user.to_s + ': ' + 'That mission gained your crew #{reward} credits each!'
                    if rand() > 0.7
                        newitem = mobot.create_item()
                        if user.inventory == ['%NONE']
                            user.inventory = [newitem]
                        else
                            user.inventory.push newitem
                        end
                        m.reply m.user.to_s + ': ' + 'You find a #{newitem[0]}!'
                    end
                end
                user.mission = true
                mobot.update_db($members)
                sleep(180)
                user.mission = false
            else
                result = mission.attempt(user.get_modded_stats)
                reward = result[2]
                m.reply m.user.to_s + ': ' + result[0]
                m.reply m.user.to_s + ': ' + result[1]
                if (user.credits + reward) < 1
                    neg = user.credits
                    user.credits = 0
                    m.reply m.user.to_s + ': ' + 'That mission lost you #{neg} credits! You now have 0 credits!'
                else
                    user.credits = user.credits + reward
                    current = user.credits
                    if reward < 0
                        reward = reward.abs
                        m.reply m.user.to_s + ': ' + 'That mission lost you #{reward} credits! You now have #{current} credits!'
                    else
                        m.reply m.user.to_s + ': ' + 'That mission gained you #{reward} credits! You now have #{current} credits!'
                        if rand() > 0.7
                            newitem = mobot.create_item()
                            if user.inventory == ['%NONE']
                                user.inventory = [newitem]
                            else
                                user.inventory.push newitem
                            end
                            m.reply m.user.to_s + ': ' + 'You find a #{newitem[0]}!'
                        end
                    end
                end
                user.mission = true
                mobot.update_db($members)
                sleep(180)
                user.mission = false
            end
        else
            m.reply m.user.to_s + ': ' + 'You don\'t have enough AP to do that!'
        end
    end

    on :message, 'help' do |m|
        User(m.user.to_s).send('Hi! I\'m mobot! I allow you to save up credits via playing games with other bots in irc such as UNOBot or Trivia, and eventually spend them rank up on #mobot!')
        User(m.user.to_s).send('Commands and documentation can be found at https://github.com/Varzeki/mobot')
    end

    on :message, 'inventory' do |m|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        m.reply m.user.to_s + ': ' + mobot.get_user(m.user.to_s, $members).show_inventory.to_s
    end

    on :message, 'item' do |m|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        m.reply m.user.to_s + ': ' + mobot.get_user(m.user.to_s, $members).item[0].to_s
    end

    on :message, /^equip/ do |m|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = m.message.split(' ')
        if lst.length > 1
            responses = mobot.get_user(m.user.to_s, $members).equip(lst[1])
            responses.each do |i|
                m.reply m.user.to_s + ': ' + i.to_s
            end
        else
            m.reply m.user.to_s + ': ' + 'You must specify an inventory slot!'
        end
    end

    on :message do |m|
        if m.user.to_s == 'Trivia'
            lst = m.message.split(' ')
            if lst[0] == 'Winner:'
                mobot.get_user(lst[1].chop, $members).add_trivia(lst[lst.index('Points:')+1].chop.to_i)
                mobot.update_db($members)
            end
        end
    end

    #FIXME
    on :message do |m|
        if m.user.to_s == 'UNOBot'
            lst = m.message.split(' ')
            if lst[1] == 'gains'
                mobot.get_user(m.user.to_s, $members).add_uno(lst[2].to_i)
            end
        end
    end

    on :message, /^CMOD (.+)/ do |m, arg|
        lst = arg.split(' ')
        amount = lst[0]
        recipient = lst[1]
        if $admins.include? m.user.to_s
            user = mobot.get_user(recipient, $members)
            user.credits = user.credits + amount.to_i
            m.reply m.user.to_s + ': ' + 'User credited!'
            mobot.update_db($members)
        else
            m.reply m.user.to_s + ': ' + 'You don\'t have permission to do that!'
        end
    end

    on :message, /^ADMIN (.+)/ do |m, arg|
        lst = arg.split(' ')
        recipient = lst[0]
        if (!config['admins'].include? recipient) && ($admins.include? m.user.to_s)
            if $admins.include? recipient
                $admins.delete_at($admins.find_index(recipient))
                m.reply m.user.to_s + ': ' + '#{recipient} was removed from admins.'
            else
                $admins.push(recipient)
                m.reply m.user.to_s + ': ' + '#{recipient} was added as an admin.'
            end
        else
            m.reply m.user.to_s + ': ' + 'You don\'t have permission to do that!'
        end
    end

    #FIXME
    on :message, /^faction (.+)/ do |m, arg|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        m.reply m.user.to_s + ': ' + lst
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
                            m.reply m.user.to_s + ': ' + 'You pay the 15000 startup cost and create a new faction!'
                        else
                            m.reply m.user.to_s + ': ' + 'You need 15000 credits to start a faction!'
                        end
                    else
                        m.reply m.user.to_s + ': ' + 'That faction already exists!'
                    end
                else
                    m.reply m.user.to_s + ': ' + 'You need to give your faction a name!'
                end
            else
                m.reply m.user.to_s + ': ' + 'You\'re already in a faction!'
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
                                m.reply m.user.to_s + ': ' + 'You paid the entry fee of 500 coins and joined #{joined}!'
                            else
                                m.reply m.user.to_s + ': ' + 'You don\'t have enough credits to pay the 500 credit entry fee!'
                            end
                        else
                            m.reply m.user.to_s + ': ' + 'You havn\'t been invited to that faction!'
                        end
                    else
                        m.reply m.user.to_s + ': ' + 'That faction doesn\'t exist!'
                    end
                else
                    m.reply m.user.to_s + ': ' + 'That faction doesn\'t exist!'
                end
            else
                m.reply m.user.to_s + ': ' + 'You\'re already in a faction!'
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
                    m.reply m.user.to_s + ': ' + 'You disband the faction!'
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
                    m.reply m.user.to_s + ': ' + 'You leave the faction!'
                end
            else
                m.reply m.user.to_s + ': ' + 'You aren\'t in a faction!'
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
                        m.reply m.user.to_s + ': ' + 'You just invited #{inv} to the faction!'
                    else
                        m.reply m.user.to_s + ': ' + 'You didn\'t specify a user!'
                    end
                else
                    m.reply m.user.to_s + ': ' + 'You don\'t have permission to do that!'
                end
            else
                m.reply m.user.to_s + ': ' + 'You aren\'t in a faction!'
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
                                    m.reply m.user.to_s + ': ' + 'Deposit successful! The faction now has #{amount}!'
                                else
                                    m.reply m.user.to_s + ': ' + 'The bank can\'t hold that much!'
                                end
                            else
                                m.reply m.user.to_s + ': ' + 'You don\'t have that many credits!'
                            end
                        else
                            m.reply m.user.to_s + ': ' + 'Please bank a valid amount!'
                        end
                    else
                        m.reply m.user.to_s + ': ' + 'Please bank a valid amount!'
                    end
                else
                    m.reply m.user.to_s + ': ' + 'Your faction is a syndicate, and can\'t bank money!'
                end
            else
                m.reply m.user.to_s + ': ' + 'You aren\'t in a faction!'
            end
        end
        if lst[0] == 'show'
            if not user.fact == '%NONE'
                fact = mobot.get_fact(user.fact)
                nm = fact.name
                bnk = fact.bank
                if fact.syndicate
                    syn = 'Syndicate'
                else
                    syn = 'Corporation'
                end
                members = fact.tier1 + fact.tier2
                lead = fact.leader
                m.reply m.user.to_s + ': ' + 'You are in the faction #{nm}, which is lead by #{lead}, has a balance of #{bnk}, and has members #{members}.'
            else
                m.reply m.user.to_s + ': ' + 'You aren\'t in a faction!'
            end
        end
    end

    on :message, /^crew (.+)/ do |m, arg|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        if lst[0] == 'start'
            if user.crew == '%NONE'
                user.crew = user.name
                user.crew_array = [user.name]
                user.crew_open = false
                mobot.update_db($members)
                m.reply m.user.to_s + ': ' + 'You started a crew!'
            else
                m.reply m.user.to_s + ': ' + 'You\'re already in a crew!'
            end
        end
        if lst[0] == 'join'
            if user.crew == '%NONE'
                user2 = mobot.get_user(lst[1], $members)
                if not user2.crew == user2.name
                    m.reply m.user.to_s + ': ' + 'That user isn\'t a crew captain!'
                else
                    if user2.crew_open == true
                        if user2.crew_array.length > 2
                            m.reply m.user.to_s + ': ' + 'That users crew is full!'
                        else
                            user2.crew_array.push(user.name)
                            user.crew = user2.name
                            cname = user2.name
                            mobot.update_db($members)
                            m.reply m.user.to_s + ': ' + 'You just joined the crew of #{cname}!'
                        end
                    else
                        m.reply m.user.to_s + ': ' + 'That users crew is closed!'
                    end
                end
            else
                m.reply m.user.to_s + ': ' + 'You\'re already in a crew!'
            end
        end
        if lst[0] == 'open'
            if user.crew == user.name
                if not user.crew_open
                    user.crew_open = true
                    m.reply m.user.to_s + ': ' + 'Your crew is now open!'
                    mobot.update_db($members)
                else
                    m.reply m.user.to_s + ': ' + 'Your crew is already open!'
                end
            else
                if user.crew == '%NONE'
                    m.reply m.user.to_s + ': ' + 'You aren\'t in a crew!'
                else
                    m.reply m.user.to_s + ': ' + 'You aren\'t the captain of this crew!'
                end
            end
        end
        if lst[0] == 'close'
            if user.crew == user.name
                if user.crew_open
                    user.crew_open = false
                    mobot.update_db($members)
                    m.reply m.user.to_s + ': ' + 'Your crew is now closed!'
                else
                    m.reply m.user.to_s + ': ' + 'Your crew is already closed!'
                end
            else
                if user.crew == '%NONE'
                    m.reply m.user.to_s + ': ' + 'You aren\'t in a crew!'
                else
                    m.reply m.user.to_s + ': ' + 'You aren\'t the captain of this crew!'
                end
            end
        end
        if lst[0] == 'leave'
            if user.crew == user.name
                user.crew_array.each do |i|
                    j = mobot.get_user(i, $members)
                    j.crew = '%NONE'
                end
                user.crew_array = []
                mobot.update_db($members)
                m.reply m.user.to_s + ': ' + 'You disband the crew!'
            else
                user2 = mobot.get_user(user.crew, $members)
                user2.crew_array = user2.crew_array - [user.name]
                user.crew = '%NONE'
                mobot.update_db($members)
                m.reply m.user.to_s + ': ' + 'You leave the crew!'
            end
        end
        if lst[0] == 'show'
            if user.crew == '%NONE'
                m.reply m.user.to_s + ': ' + 'You aren\'t in a crew!'
            else
                open = mobot.get_user(user.crew, $members).crew_open
                if open
                    status = 'OPEN'
                else
                    status = 'CLOSED'
                end
                owner = user.crew
                members = mobot.get_user(user.crew, $members).crew_array
                m.reply m.user.to_s + ': ' + 'This #{status} crew is owned by #{owner} and has members #{members}.'
            end
        end
    end

    on :message, /^rob (.+)/ do |m, arg|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = arg.split(' ')
        robber = mobot.get_user(m.user.to_s, $members)
        victim = mobot.get_user(lst[0], $members)
        if robber.ap > 0
            robber.ap = robber.ap - 1
            if robber == victim
                m.reply 'You\'re seriously trying to rob yourself? What a masochist!'
            end
            amount = victim.robbed
            robber.credits = robber.credits + amount - 20
            current = robber.credits
            if amount > 0
                m.reply 'You successfully stole #{amount} credits! You now have #{current} credits!'
            else
                m.reply 'You failed to steal anything! You now have #{current} credits!'
            end
            mobot.update_db($members)
        else
            m.reply 'You don\'t have enough AP to do that!'
        end
    end

    on :message, /^purchase (.+)/ do |m, arg|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = arg.split(' ')
        item = lst[0]
        recipient = lst[1]
        m.reply mobot.get_user(m.user.to_s, $members).buy(item, recipient, m)
        mobot.update_db($members)
    end

    on :message, '.bots' do |m|
        m.reply '[Ruby] https://github.com/Varzeki/mobot | Try using .help for commands!'
    end

    on :message, 'MIGRATE' do |m|
        if $admins.include? m.user.to_s
            m.reply m.user.to_s + ': ' + 'Migrating database...'
            new_db = []
            $members.each do |i|
                new_db.push(Member.new(i.name, i.credits, i.dex, i.str, i.int, i.lck, i.crew, i.crew_array, i.crew_open, i.access, i.inventory, i.item, i.ap, i.psi, i.acc))
            end
            $members = new_db
            mobot.update_db($members)
            m.reply m.user.to_s + ': ' + 'Done!'
        else
            m.reply m.user.to_s + ': ' + 'You don\'t have permission to do that!'
        end
    end

    on :message, /^bet (.+)/ do |m, arg|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        lst = arg.split(' ')
        user = mobot.get_user(m.user.to_s, $members)
        if lst[0].to_i > 1
            if user.credits - lst[0].to_i > -1
                if rand() > 0.52
                    user.credits = user.credits + lst[0].to_i
                    amount = user.credits
                    m.reply m.user.to_s + ': ' + 'Congratulations, you won! You now have #{amount} credits!'
                else
                    user.credits = user.credits - lst[0].to_i
                    amount = user.credits
                    m.reply m.user.to_s + ': ' + 'You lost! You now have #{amount} credits!'
                end
            end
            mobot.update_db($members)
        end
    end

    on :message, /^give (\S+) (\d+)/ do |m, target, amount|
        if force_mobot_channel == true && m.channel != '#mobot'
            m.reply(m.user.to_s + ': ' + 'Commands only work in #mobot!')
            next
        end

        userGiver = mobot.get_user(m.user.to_s, $members)
        userReciever = mobot.get_user(target,$members)
        amount = Integer(amount)
        fee = (amount*0.01).ceil
        combined = amount + fee

        if userGiver.credits >= combined
            userGiver.credits -= combined
            userReciever.credits += amount
            m.reply m.user.to_s + ': ' + "#{userGiver.name} transfered #{amount} #{amount != 1 ? 'credits' : 'credit'} to #{userReciever.name}. #{fee} #{fee != 1 ? 'credits were ' : 'credit was'} charged for the transaction."
            mobot.update_db($members)
        else
            m.reply m.user.to_s + ': ' + "You need #{combined} credits to transfer #{amount} to #{userReciever.name}."
        end
    end
end

# Set logging
mobot.loggers << Cinch::Logger::FormattedLogger.new(File.open('./mobot.log', 'a'))
mobot.loggers.level = :debug
mobot.loggers.first.level = :info

# Start
mobot.start
