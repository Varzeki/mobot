require 'yaml'

class Mission
    attr_accessor :name, :type, :reward, :start, :success, :failure
    attr_accessor :authors, :outcomes

    def initialize(name, type, reward, start, success, failure)
        @name = name
        @type = type
        @reward = reward
        @start = start
        @success = success
        @failure = failure
    end

    #Alternative Constructor via yaml
    def self.fromYAML(yamlInput)
        @name = yamlInput["title"]
        @type = yamlInput["name"]
        @start = yamlInput["mission"]["info"]
    end

    def attempt(stats)
        responses = [@start]
        if @type == "DEX"
            if rand() > 0.3
                responses.push(@success)
                responses.push(@reward + (stats[0] * 7)
            else
                responses.push(@failure)
                responses.push(0 - @reward)
            end
        end
        if @type == "STR"
            if rand() > 0.3
                responses.push(@success)
                responses.push(@reward + ((stats[1] * 7) + (stats[3] * 2)))
            else
                responses.push(@failure)
                responses.push(0 - @reward)
            end
        end
        if @type == "INT"
            if rand() > 0.3
                responses.push(@success)
                responses.push(@reward + ((stats[2] * 7) + (stats[3] * 2)))
            else
                responses.push(@failure)
                responses.push(0 - @reward)
            end
        end
        if @type == "LCK"
            if rand() > 0.3
                responses.push(@success)
                responses.push(@reward + stats[3] * 7)
            else
                responses.push(@failure)
                responses.push(0 - @reward)
            end
        end
        if @type == "PSI"
            if rand() > 0.3
                responses.push(@success)
                responses.push(@reward + stats[4] * 7)
            else
                responses.push(@failure)
                responses.push(0 - @reward
            end
        end
        if @type == "ACC"
            if rand() > 0.3
                responses.push(@success)
                responses.push(@reward + stats[5] * 7)
            else
                responses.push(@failure)
                responses.push(0 - @reward
            end
        end
        responses
    end
end

def loadMissions
    tmpArray = []
    for path in Dir["missions/**/*.yaml"]
      puts "Loaded mission from file: #{path}"
      mission = YAML.load_file(path)
      tmpArray.push(Mission.new(mission["title"], mission["attr"], mission["reward"], mission["info"], mission["success"], mission["fail"]))
    end
    return tmpArray
end
