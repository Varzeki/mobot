def create_item()
    rng = rand()
    if rng < 0.6
        prefix = "Regulation"
        stats = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
        value = rand() * 1000
    elsif rng < 0.865
        prefix = "Industrial"
        stats = [0.3, 0.3, 0.3,0.3,0.3,0.3]
        value = rand() * 4000
    elsif rng < 0.94
        prefix = "Aftermarket"
        stats = [0.5,0.5,0.5,0.5,0.5,0.5]
        value = rand() * 7000
    elsif rng < 0.975
        prefix = "Illegal"
        stats = [0.7,0.7,0.7,0.7,0.7,0.7]
        value = rand() * 10000
    elsif rng < 0.995
        prefix = "Starframed"
        stats = [0.9,0.9,0.9,0.9,0.9,0.9]
        value = rand() * 15000
    else
        prefix = "Zekiforged"
        stats = [1.5,1.5,1.5,1.5,1.5,1.5]
        value = 100000
    end
    weapon = ["Arclance", "Dynawrench", "Gravaxe", "Fusion Rifle", "Neuralyzer", "Gauss Matrix", "Implant", "Bionics", "Psiglass"].sample
    element = ["Aer", "Terra", "Aques", "Fyr", "Flux", "Alica"].sample
    if element == "Aer"
        stats[0] += 0.2
    elsif element =="Terra"
        stats[1] += 0.2
    elsif element =="Aques"
        stats[2] += 0.2
    elsif element == "Fyr"
        stats[3] += 0.2
    elsif element == "Flux"
        stats[4] += 0.2
    else
        stats[5] += 0.2
    end

    name = "#{prefix} #{weapon} of #{element}"
    [name, stats, value]
end

Kernel.loop {puts create_item() }
